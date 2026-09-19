# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

A 3-day take-home assessment: a **Sharetribe Flex** marketplace with a modified transaction process, plus a **Flutter** app that logs in to Sharetribe and lists listings. Full brief is in `README.md`.

**No code exists yet.** The repo holds only planning docs:
- `docs/analysis-of-requirements.md`: scope, planned architecture, definition of done.
- `docs/q-and-a.md`: open questions for the reviewer. Blockers include marketplace type, which process change to make, and whether the app must start a transaction. Its "Working decisions" table records the answers the plan assumes and marks each one Assumed, Decided or Open. Recheck an Assumed or Open row before building anything that depends on it.
- `docs/plan.md`: the phased build plan (P0–P7), agent session prompts, and the locked stack. Follow its "Lock so the agent cannot drift" section.

## Planned layout

```text
sharetribe/
  process.edn          # exported + modified transaction process
  PROCESS_CHANGES.md   # what changed, why, how versioning keeps old transactions safe
flutter_app/
  lib/
    data/              # REST client (dio), token storage, DTOs
    domain/            # Listing, User, failures, use cases
    presentation/      # login + listings screens (flutter_bloc Cubits)
```

## Architecture decisions (from the analysis doc)

- **No official Dart SDK.** Call Sharetribe REST directly:
  - `POST https://flex-api.sharetribe.com/v1/auth/token`: `password` grant for login, `refresh_token` grant for refresh, and `client_credentials` for anonymous browsing if that is in scope.
  - `GET https://flex-api.sharetribe.com/v1/listings?include=author,images`
- **Two APIs, two trust levels.** The Marketplace API uses the Client ID and a user token, and it is the only API the Flutter app may use. The Integration API uses the Client Secret, so the secret must **never** reach the app or the repo.
- **Responses are JSON:API.** Denormalize `data` + `included` (author, images) in the data layer and map them to domain models. Widgets should never parse raw maps.
- **Auth loop:** log in → store access + refresh tokens in `flutter_secure_storage` → a dio `QueuedInterceptor` adds `Authorization: Bearer` → on a 401, refresh once (a single refresh even when several requests fail at once) and retry → logout clears the stored tokens → restore the session on launch.
- **Client ID** comes from `--dart-define` (or a gitignored `.env`), never hard-coded.
- **Transaction process changes ship as a new release.** Push the new version, create a new `simple-request/release-2` alias, and re-point the listing type to it. `release-1` stays on version 1, so never move or edit it. The change must add real behavior, such as a new state, actor transition, or privileged operator step, not just rename something. The recommended change is request-to-book (a provider-accept step).
- The listings UI needs loading, empty, and error states, plus pull-to-refresh. Styling is Material 3 with no design system. The priority is functionality and structure, not visuals.

## Commands

Toolchain: Flutter 3.47.x stable. Once `flutter_app/` exists, run these from inside it:

- run (mock, offline): `flutter run --dart-define=SHARETRIBE_MODE=mock`
- run (live): `flutter run --dart-define=SHARETRIBE_MODE=live --dart-define=SHARETRIBE_CLIENT_ID=<id>`
- verify (definition of done): `make verify` (runs `flutter analyze` then `flutter test`; includes `test/app_mock_test.dart`, which starts the full app in mock mode)
- test all: `flutter test`
- single test: `flutter test test/path/to_test.dart` (add `--plain-name "<name>"` to run one case)
- lint: `flutter analyze`

The planned tests are unit tests for the JSON:API mapping and for the token-refresh interceptor.

## Gotchas

- `.gitignore` is a copy of the Flutter SDK's own ignore file. It ignores `*.lock` globally, so the project section at the bottom re-includes `pubspec.lock` and ignores `.env` / `.env.*` (except `.env.example`). Keep new project rules in that section.
- Done means: the listing type uses the new process release, a sandbox user can log in through the app and see titles and prices, and a stranger can reproduce the whole setup from the README in under 30 minutes.
