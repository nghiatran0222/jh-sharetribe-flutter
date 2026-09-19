# 0006. Agent instructions: AGENTS.md is the single source; CLAUDE.md imports it

- Status: Accepted
- Date: 2026-09-20
- Phase: P0

## Context

The plan targets more than one coding agent (Claude Code and Grok Build). An early plan draft said to copy the same rules into both `AGENTS.md` and `CLAUDE.md`, and two copies drift apart.

## Decision

All agent rules and project facts live in **`AGENTS.md`**. `CLAUDE.md` contains only `@AGENTS.md`, which Claude Code imports.

## Alternatives rejected

- **Two maintained copies**: they drift, and an agent then follows stale rules.
- **`CLAUDE.md` only**: other agents don't read it.

## Consequences

- Edit `AGENTS.md`, never `CLAUDE.md`.
- Claude Code picks up changes on the next session start.
