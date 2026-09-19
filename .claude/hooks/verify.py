#!/usr/bin/env python3
"""Verify hooks for flutter_app/ (ADR 0012).

  verify.py post   PostToolUse on Edit/Write: `dart format` + `dart analyze --fatal-infos`
                   on the edited .dart file under flutter_app/. Exit 2 feeds issues back.
  verify.py stop   Stop: `make verify` in flutter_app/ when it has uncommitted changes.
                   Exit 2 blocks stopping until it is green (once per stop attempt).

FVM users: export FLUTTER="fvm flutter" DART="fvm dart".
"""
import json
import os
import shlex
import subprocess
import sys

ROOT = os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
APP = os.path.join(ROOT, "flutter_app")


def run(cmd, cwd=APP, timeout=600):
    p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout)
    return p.returncode, (p.stdout + p.stderr).strip()


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(2)


def post(data) -> None:
    path = (data.get("tool_input") or {}).get("file_path", "")
    path = os.path.abspath(os.path.join(ROOT, path))
    if not path.endswith(".dart") or not path.startswith(APP + os.sep) or not os.path.exists(path):
        return
    dart = shlex.split(os.environ.get("DART", "dart"))
    run(dart + ["format", path], timeout=60)
    code, out = run(dart + ["analyze", "--fatal-infos", path], timeout=120)
    if code != 0:
        fail(f"dart analyze found issues in {os.path.relpath(path, ROOT)} (file was also formatted):\n{out[-4000:]}")


def stop(data) -> None:
    if data.get("stop_hook_active") or not os.path.exists(os.path.join(APP, "Makefile")):
        return
    code, changed = run(["git", "status", "--porcelain", "--", "."])
    if code != 0 or not changed:
        return
    flutter = os.environ.get("FLUTTER", "flutter")
    code, out = run(["make", "verify", f"FLUTTER={flutter}"])
    if code != 0:
        fail(f"`make verify` failed in flutter_app/ (definition of done). Fix it before stopping:\n{out[-6000:]}")


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        data = {}
    {"post": post, "stop": stop}[sys.argv[1]](data)


if __name__ == "__main__":
    main()
