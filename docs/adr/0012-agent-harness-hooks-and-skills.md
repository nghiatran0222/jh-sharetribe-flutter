# 0012. Agent harness: guard hook now, verify hooks at end of P2a, skills for repeated procedures

- Status: Accepted
- Date: 2026-09-20
- Phase: P0 follow-up (guard, `new-adr`); P2a (verify hooks, added 2026-09-20); P6 (review)

## Context

The AGENTS.md rules that matter most (process.edn frozen after P1, no `.env` or secrets, `flex-cli` is human-only) were enforced only by the agent reading and obeying them. A single slip, such as an agent "fixing" `process.edn` or running `flex-cli process push`, would edit a frozen model or touch the live marketplace. Separately, the ADR procedure (number, template, index, q-and-a link) is repeated every phase and is easy to do half-way. `docs/plan.md` listed hooks and skills only as options, with no phase.

## Decision

Add a project `PreToolUse` guard hook (`.claude/settings.json` → `.claude/hooks/guard.py`) now. It blocks Edit/Write on `sharetribe/*/process.edn`, writing `.env` / `.env.*` (except `.env.example`), `flex-cli` in Bash, and Bash commands that write to `process.edn`. Add a `new-adr` project skill for the ADR procedure. Add verify hooks (PostToolUse `dart format` + `flutter analyze`; Stop hook running `make verify`) only at the end of P2a, when `make verify` exists.

## Alternatives rejected

- **Rules in AGENTS.md only**: that is what we had; it depends on the agent never slipping.
- **`permissions.deny` rules instead of a hook**: they cover tool paths but not patterns inside Bash commands (e.g. `cd sharetribe && flex-cli ...`), and they give the agent no reason to act on.
- **Verify hooks now**: they would fail on every edit until `flutter_app/` exists.
- **`flutter test` after every edit**: too slow; tests run once, in the Stop hook.

## Consequences

- A deliberate process change (a new version) needs the user to make the edit, or to disable the hook for that step. That is intended: process changes are human-approved.
- The Bash check is a pattern match. It blocks any Bash command whose text contains `flex-cli`, including a script that only writes documentation about it; use Edit/Write for such docs. A Bash command that writes `process.edn` in a form the patterns miss (e.g. a Python one-liner) is not caught; the Edit/Write block and review remain the backstop.
- The guard is tested by piping sample tool inputs to `guard.py` (7 blocked, 7 allowed cases).
- P2a added the verify hooks in `.claude/hooks/verify.py`. PostToolUse runs `dart format` + `dart analyze --fatal-infos` on the edited `.dart` file under `flutter_app/`. That is the same analyzer and `analysis_options.yaml` as `flutter analyze`, about 2 s per file against about 13 s. Stop runs `make verify` only when `flutter_app/` has uncommitted changes, and skips when `stop_hook_active` is set. FVM users export `FLUTTER="fvm flutter" DART="fvm dart"`.
