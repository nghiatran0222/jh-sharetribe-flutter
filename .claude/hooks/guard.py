#!/usr/bin/env python3
"""PreToolUse guard: blocks moves AGENTS.md forbids (ADR 0012).

- Edits to sharetribe/*/process.edn (frozen after P1; a change is a new process version + ADR).
- Writing .env / .env.* files (except .env.example).
- flex-cli in Bash (human-only step, P7).
- Plugin skills that contradict the locked stack (ADR 0014): skillOverrides does not
  hide plugin skills, so the Skill call itself is blocked.
- Adding banned packages to pubspec.yaml or via `pub add` (AGENTS.md stack lock, ADR 0014).

Exit 2 blocks the tool call and feeds stderr back to the agent.
"""
import json
import re
import sys

# dart-flutter plugin skills that teach a banned package or pattern (ADR 0014).
BLOCKED_SKILLS = {
    "flutter-use-http-package": "uses package:http; this repo uses dio (ADR 0002)",
    "flutter-setup-declarative-routing": "uses go_router, which AGENTS.md bans",
    "flutter-implement-json-serialization": "generic fromJson/toJson skips JSON:API denormalizing (json_api.dart, ADR 0011)",
    "flutter-apply-architecture-best-practices": "teaches ChangeNotifier ViewModels + provider/get_it; this repo uses Cubits (ADR 0001)",
    "dart-generate-test-mocks": "adds mockito + build_runner; tests use a fake HttpClientAdapter and hand-written fakes",
}
BANNED_PACKAGES = (
    "http", "go_router", "provider", "riverpod", "flutter_riverpod", "hooks_riverpod",
    "freezed", "freezed_annotation", "get_it", "mockito", "build_runner", "json_serializable",
)
_PKG = "|".join(BANNED_PACKAGES)
PUBSPEC = re.compile(r"(^|/)pubspec\.yaml$")
PUBSPEC_DEP = re.compile(rf"^\s+({_PKG})\s*:", re.MULTILINE)
PUB_ADD = re.compile(rf"\bpub\s+add\b[^\n;&|]*?(?<![\w-])(?:dev:|override:)?({_PKG})(?![\w-])")

PROCESS_EDN = re.compile(r"(^|/)sharetribe/[^/]+/process\.edn$")
ENV_FILE = re.compile(r"(^|/)\.env(\.[^/]*)?$")
FLEX_CLI = re.compile(r"(^|[\s;&|(`])flex-cli(\s|$)")
# Bash commands that write to a process.edn (reads such as cat/grep stay allowed).
BASH_EDN_WRITE = re.compile(
    r"(sed\s+-i|perl\s+-[a-z]*i|\btee\b|\bmv\b|\bcp\b|\brm\b|>\s*\S*)[^\n]*process\.edn"
    r"|process\.edn[^\n]*(>|\btee\b)"
)


def block(reason: str) -> None:
    print(f"Blocked by .claude/hooks/guard.py: {reason}", file=sys.stderr)
    sys.exit(2)


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        return
    tool = data.get("tool_name", "")
    tool_input = data.get("tool_input") or {}

    if tool == "Skill":
        name = str(tool_input.get("skill", "")).split(":")[-1]
        if name in BLOCKED_SKILLS:
            block(f"skill '{name}' is disabled in this repo: {BLOCKED_SKILLS[name]} (ADR 0014).")
        return

    if tool == "Bash":
        cmd = tool_input.get("command", "")
        if FLEX_CLI.search(cmd):
            block("flex-cli is a human-only step (AGENTS.md Rules, P7). Ask the user to run it.")
        if BASH_EDN_WRITE.search(cmd):
            block("process.edn is frozen after P1. A change is a new process version plus an ADR; ask the user.")
        m = PUB_ADD.search(cmd)
        if m:
            block(f"package '{m.group(1)}' is outside the locked stack (AGENTS.md, ADR 0014). Ask the user; a change needs an ADR.")
        return

    path = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
    if PROCESS_EDN.search(path):
        block("process.edn is frozen after P1. A change is a new process version plus an ADR; ask the user.")
    if ENV_FILE.search(path) and not path.endswith(".env.example"):
        block(".env files must never be written or committed (AGENTS.md Rules).")
    if PUBSPEC.search(path):
        new_text = tool_input.get("content") or tool_input.get("new_string") or ""
        new_text += "\n".join(e.get("new_string", "") for e in tool_input.get("edits") or [])
        m = PUBSPEC_DEP.search(new_text)
        if m:
            block(f"package '{m.group(1)}' is outside the locked stack (AGENTS.md, ADR 0014). Ask the user; a change needs an ADR.")


if __name__ == "__main__":
    main()
