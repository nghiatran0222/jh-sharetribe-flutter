# 0014. Official Flutter agent skills, filtered by a hook; Dart MCP server from the plugin

- Status: Accepted
- Date: 2026-09-20
- Phase: P0 follow-up (used from P2a on)

## Context

Flutter publishes official agent skills and the Dart MCP server as the `dart-flutter` Claude Code plugin (`flutter/agent-plugins`, v1.0.5, Flutter 3.47+). Version 1.0.5 ships 25 skills (10 Flutter, 15 Dart) plus `dart mcp-server` (analyzer diagnostics, symbol lookup, test runner). Skills are model-invoked: an agent picks one when its description matches the task. Five of them teach what this repo's Accepted ADRs forbid:

| Skill | Conflict |
|--|--|
| `flutter-use-http-package` | `package:http`; we use dio (ADR 0002) |
| `flutter-setup-declarative-routing` | go_router, banned in AGENTS.md |
| `flutter-implement-json-serialization` | generic `fromJson`/`toJson`, skipping JSON:API denormalizing (ADR 0011) |
| `flutter-apply-architecture-best-practices` | `ChangeNotifier` ViewModels + `provider`/`get_it`; we use Cubits (ADR 0001) |
| `dart-generate-test-mocks` | mockito + build_runner; tests use a fake `HttpClientAdapter` and hand-written fakes |

`skillOverrides` in `.claude/settings.json` was tested and does **not** hide plugin skills (with or without the `dart-flutter:` prefix); it only hid a project skill.

## Decision

Install the `dart-flutter` plugin at **project scope** (marketplace and plugin recorded in `.claude/settings.json`) and use its bundled Dart MCP server; no separate `.mcp.json`. The guard hook (ADR 0012) **blocks the `Skill` call** for the five skills above, and blocks adding banned packages (`http`, `go_router`, `provider`, `riverpod`, `flutter_riverpod`, `hooks_riverpod`, `freezed`, `freezed_annotation`, `get_it`, `mockito`, `build_runner`, `json_serializable`) through `pubspec.yaml` edits or `pub add`. The plugin's rules files are not added; AGENTS.md stays the single source (ADR 0006).

## Alternatives rejected

- **No plugin**: loses the MCP server and the useful skills (`flutter-add-widget-test`, `flutter-fix-layout-issues`, `flutter-build-responsive-layout`).
- **Whole plugin, unfiltered**: a routine request such as "fetch listings" can pull the agent to `http` or `ChangeNotifier`, silently undoing ADRs 0001/0002/0011.
- **`skillOverrides`**: tested; no effect on plugin skills.
- **Separate `.mcp.json` for `dart mcp-server`**: the plugin already starts it; a second entry would run two servers.
- **Plugin rules in CLAUDE.md**: would compete with AGENTS.md.

## Consequences

- Anyone opening the repo in Claude Code is prompted to trust the `dart-flutter` marketplace and plugin.
- The blocked skills stay visible in the skill list; calling one returns the hook's reason. Their advice could still reach the agent another way (e.g. reading the SKILL.md file); the package block in `pubspec.yaml` is the backstop that matters.
- A plugin update may add or rename skills. After updating, list the skills again and review new ones against the ADRs.
- Adding any package on the banned list needs a new ADR, and the list in `.claude/hooks/guard.py` must change with it.
