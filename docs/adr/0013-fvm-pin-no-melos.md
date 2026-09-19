# 0013. Pin Flutter 3.47.4 with FVM (optional); no Melos

- Status: Accepted
- Date: 2026-09-20
- Phase: P0 follow-up (applied in P2a and P5)

## Context

AGENTS.md said "Flutter 3.47.x stable", and `docs/q-and-a.md` Important 4 left the version open. The assessment is done only when a stranger can reproduce everything from the README in under 30 minutes; a reviewer on another Flutter version can hit different analyzer rules or API changes, and `make verify` would no longer be the same check for everyone. Two tools came up: FVM (per-project Flutter version pinning) and Melos (multi-package Dart workspaces). The repo has one Dart package, `flutter_app/`.

## Decision

Pin **Flutter 3.47.4** (stable) in a committed `.fvmrc` at the repo root. FVM is **optional**: the Makefile calls `$(FLUTTER)` (default `flutter`), so any Flutter 3.47.x works, and FVM users run `make verify FLUTTER="fvm flutter"`. **Do not use Melos.**

## Alternatives rejected

- **Version in docs only**: nothing checks it, and agents and reviewers drift.
- **FVM required**: one more install step for a reviewer with a 30-minute budget, for no gain when their global Flutter is already 3.47.x.
- **Melos**: it manages several packages (bootstrap, linking, scripts across packages, versioning). With one package it adds a `melos.yaml`, a global install and a second way to run commands, and solves nothing.
- **Dart pub workspaces**: same reason as Melos; there is nothing to share yet.

## Consequences

- `.fvmrc` is committed; `.fvm/` (the local SDK link) is ignored in the project section of `.gitignore`.
- The P2a Makefile uses `FLUTTER ?= flutter`, and the verify hooks added in P2a (ADR 0012) must call `$(FLUTTER)` / `make verify`, not a hard-coded `flutter`.
- The P5 README says "Flutter 3.47.x, or `fvm install` if you use FVM".
- Important 4 is decided for the version only; target platforms stay open.
- Revisit Melos (or pub workspaces) only if code is split into `packages/`, e.g. a standalone `sharetribe_api` Dart package; that would be a new ADR.
