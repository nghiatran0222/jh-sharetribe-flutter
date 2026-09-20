# Sharetribe Flutter assessment

Guidance for coding agents (Claude Code reads it via `CLAUDE.md` → `@AGENTS.md`). This is the single source of truth: edit this file, not `CLAUDE.md`.

## Project status

A 3-day take-home assessment: a **Sharetribe Flex** marketplace with a modified transaction process, plus a **Flutter** app that logs in to Sharetribe and lists listings. The brief is in `docs/brief.md`; the submission README is the repo root `README.md`.

**Status (2026-09-20):** P1–P6 done. The process v1/v2 is approved and frozen in `sharetribe/`. The Flutter app is built and `make verify` is green (72 tests): foundations, JSON:API, dio client with refresh, mock and live repositories, login and listings on Cubits, plus an E2E suite on a simulator (ADR 0016). Remaining: **P7, the human live gate** (Console, `flex-cli`, one live login, and capturing a real `listings/query` fixture), and the optional P4b stretch (Transaction repository and Request button). P6's adversarial review is in `docs/review-p6.md`.

Planning docs:
- `docs/plan.md`: phased build plan (P0–P7), agent session prompts, human gates. Its "Lock so the agent cannot drift" section is binding.
- `docs/q-and-a.md`: questions for the reviewer. Its "Working decisions" table marks each answer Assumed, Decided or Open. Recheck an Assumed or Open row before building anything that depends on it.
- `docs/analysis-of-requirements.md`: scope and reasoning behind the plan.
- `docs/adr/`: Architecture Decision Records (why the stack and rules are what they are). Index: `.claude/second-brain/decisions.md`.
- `.claude/second-brain/glossary.md`: domain terms and contexts (Identity, Catalog, Transactions). Use its names in code and tests.

## Stack

Dart 3 / Flutter 3.47.4 stable (pinned in `.fvmrc`; FVM optional, no Melos: ADR 0013), flutter_bloc (Cubit), dio, flutter_secure_storage.
Sharetribe Marketplace API (JSON:API) over REST. There is no official Flutter/Dart SDK.

## Layout

```text
sharetribe/
  simple-request/        # v1 baseline process.edn + templates
  simple-request-v2/     # v2 change + CHANGELOG.md
  README.md              # flex-cli create/push/alias steps
flutter_app/
  lib/
    core/                # Env, Result, AppError
    data/                # json_api.dart, sharetribe/ (client, TokenStore, guard, live repos), mock/
    domain/              # models + abstract repositories
    presentation/        # Cubits + login, listings pages
    app.dart             # RepositoryProvider / BlocProvider wiring
    app_dependencies.dart# composition root: mock or live from Env
  assets/mock/           # bundled listing images, so mock mode needs no network
  test/                  # json_api, refresh, repos, Cubits, pages, app_mock_test.dart
  integration_test/      # E2E on a device: real SecureTokenStore (ADR 0016)
  test_driver/           # writes docs/screenshots/ during `make e2e`
```

## Architecture

presentation (Cubits) → domain repositories → data (mock | live `SharetribeClient`) → flutter_secure_storage.
Do not add a backend. Do not use the Integration API.

- **Endpoints** (host `https://flex-api.sharetribe.com`; Marketplace API paths carry the `/v1/api/` prefix, auth does not): `POST /v1/auth/token` (`password` grant with `scope=user` for login, `refresh_token` grant for refresh, `client_credentials` for an anonymous token), `POST /v1/auth/revoke` on logout, `GET /v1/api/current_user/show`, and `GET /v1/api/listings/query?include=author,images` plus an explicit image variant via `fields.image`. Verified against the Marketplace API reference in P6.
- **Two trust levels:** the Marketplace API uses the public Client ID and a user token, and it is the only API the app may call. The Integration API uses the Client Secret, which never reaches the app or the repo.
- **JSON:API:** `data` + `included` (author, images) are denormalized in `data/json_api.dart` and mapped by `Listing.fromJsonApi`. Widgets never parse raw maps.
- **Auth loop:** log in → store access + refresh tokens with flutter_secure_storage → a dio `QueuedInterceptor` adds `Authorization: Bearer` → on a 401, refresh once and retry (one refresh even when several requests fail at once; persist the rotated refresh token) → logout clears the tokens → restore the session on launch.
- **Run modes** come from dart-defines: `SHARETRIBE_MODE` (`mock` | `live`, default `mock`) and `SHARETRIBE_CLIENT_ID` (live only), read by `core/Env`.
- **Process versioning:** v2 (provider accept/decline, 3-day expiry, ADR 0007) ships as a new version behind a new `simple-request/release-2` alias. The app picks it by sending `processAlias: simple-request/release-2` with `transition/request` on `transactions/initiate`. `release-1` stays on version 1. Transactions already started on v1 keep running on v1.
- **UI:** Material 3, no design system. Listings need loading, empty and error states, pull-to-refresh, and logout. Functionality and structure come before visuals.

## Commands

Run from `flutter_app/`:

- verify (definition of done): `make verify` (runs `flutter analyze` then `flutter test`, including `test/app_mock_test.dart`, which starts the full app in mock mode). With FVM: `make verify FLUTTER="fvm flutter"`, and prefix the commands below with `fvm`.
- test: `flutter test`; one file: `flutter test test/<file>_test.dart`; one case: add `--plain-name "<name>"`
- e2e (needs a booted device, not part of verify): `make e2e DEVICE=<device-id>`. Runs `integration_test/` against the real `SecureTokenStore` and rewrites `docs/screenshots/` (ADR 0016).
- lint: `flutter analyze`
- run mock (offline): `flutter run --dart-define=SHARETRIBE_MODE=mock`
- run live: `flutter run --dart-define=SHARETRIBE_MODE=live --dart-define=SHARETRIBE_CLIENT_ID=<id>`

From the repo root:

- process check (offline, structure only): `python3 scripts/check_process.py sharetribe/simple-request sharetribe/simple-request-v2`. The real validator is `flex-cli process --path <dir>`, a human step (see `sharetribe/README.md`).

## Rules

- Never commit `SHARETRIBE_CLIENT_ID`, any client secret, or a `.env` file. Never put the Integration API secret in the app.
- Once P1 is approved, do not edit `sharetribe/simple-request*/process.edn` unless asked. Never move or edit the `release-1` alias.
- Do not swap the stack: no Provider, Riverpod, http, go_router or freezed. Add packages only when required.
- Mock mode must run without network. The README leads with the live run; mock is the offline fallback.
- `Result`/`AppError` is the error type. No uncaught throws in repositories. A missing image variant maps to a null image.
- Token refresh lives only in the dio `QueuedInterceptor`.
- Name tests as behaviors: `group('given <state>')` + `test('when <action>, then <outcome>')`; `bloc_test` descriptions read `emits [...] when ...`. No Gherkin or `.feature` files.
- The Transaction repository and Request button are stretch work (P4b), only after P4 is green.
- Console, `flex-cli` and live credentials are human-only steps. Stop and ask instead of attempting them.
- One writer at a time on `flutter_app/lib`.
- Every new architecture decision gets an ADR: copy `docs/adr/template.md` to the next `docs/adr/NNNN-title.md`, add one line to `.claude/second-brain/decisions.md`, and link it from the matching row in `docs/q-and-a.md`. Never contradict an Accepted ADR without writing a new ADR that supersedes it (and marking the old one "Superseded by"). Use the `new-adr` skill (`.claude/skills/new-adr/`).
- A `PreToolUse` hook (`.claude/hooks/guard.py`, ADRs 0012 and 0014) blocks edits to `process.edn`, writing `.env` files, `flex-cli` in Bash, five `dart-flutter` plugin skills that contradict the stack, and adding banned packages (`http`, `go_router`, `provider`, riverpod, `freezed`, `get_it`, `mockito`, `build_runner`, `json_serializable`). If it blocks you, stop and ask; do not work around it.
- The `dart-flutter` plugin (ADR 0014) provides the Dart MCP server and Flutter/Dart skills. Prefer its MCP tools for analysis and tests. When a skill's advice conflicts with an ADR or this file, the ADR wins.

## Gotchas

- `.gitignore` is a copy of the Flutter SDK's own ignore file and ignores `*.lock` globally. The project section at the bottom re-includes `pubspec.lock` and ignores `.env` / `.env.*` (except `.env.example`). Add new project rules to that section.
- The guard hook matches Bash command text, so any Bash command containing `flex-cli` is blocked, even one that only edits docs. Use Edit/Write for text that mentions it.
- The whole assessment is done when: the listing type uses `simple-request/release-2`, a sandbox user can log in through the app and see titles and prices, and a stranger can reproduce everything from the README in under 30 minutes.
