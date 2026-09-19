#!/usr/bin/env python3
"""PreToolUse guard: blocks moves AGENTS.md forbids (ADR 0012).

- Edits to sharetribe/*/process.edn (frozen after P1; a change is a new process version + ADR).
- Writing .env / .env.* files (except .env.example).
- flex-cli in Bash (human-only step, P7).

Exit 2 blocks the tool call and feeds stderr back to the agent.
"""
import json
import re
import sys

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

    if tool == "Bash":
        cmd = tool_input.get("command", "")
        if FLEX_CLI.search(cmd):
            block("flex-cli is a human-only step (AGENTS.md Rules, P7). Ask the user to run it.")
        if BASH_EDN_WRITE.search(cmd):
            block("process.edn is frozen after P1. A change is a new process version plus an ADR; ask the user.")
        return

    path = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
    if PROCESS_EDN.search(path):
        block("process.edn is frozen after P1. A change is a new process version plus an ADR; ask the user.")
    if ENV_FILE.search(path) and not path.endswith(".env.example"):
        block(".env files must never be written or committed (AGENTS.md Rules).")


if __name__ == "__main__":
    main()
