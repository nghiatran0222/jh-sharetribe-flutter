# 0004. Run modes: mock is the default for dev and tests; the README leads with live

- Status: Accepted
- Date: 2026-09-20
- Phase: P0 (applied in P2a and P5)

## Context

Agents have no Sharetribe credentials, and a device-free `make verify` is the definition of done, so the app must work without the network. But the brief asks for an app that "authenticates with Sharetribe", and a reviewer who only sees mock data could conclude there is no real integration.

That needs a way to pass two values into the app: the mode, and the Client ID in live mode. A `.env` file read at runtime is the familiar answer, so the choice against it is recorded here rather than left to be re-argued.

## Decision

`SHARETRIBE_MODE` (a dart-define) selects `mock` or `live`, and defaults to **`mock`**. Tests and the full-app `test/app_mock_test.dart` run in mock mode. The root README presents the **live run first** and mock as the offline fallback. Dart-defines are the only config mechanism; `core/Env` is the only place that reads them.

## Alternatives rejected

- **Live by default**: tests and agents would need credentials and the network, so `make verify` couldn't run on its own.
- **Mock only**: fails the brief.
- **A recorded-HTTP fixture layer instead of mock repositories**: more realistic, but a bigger build for a 3-day assessment. Unit tests already cover the live client with a fake `HttpClientAdapter`.
- **A `.env` file at runtime (`flutter_dotenv`)**: `.env` is a server practice. It works because the file stays on a host you control and the process reads it from its environment. A Flutter app has neither: there is no process environment on a device, and a `.env` shipped with the app is a bundled asset that `unzip` (or, on web, the browser) reads, so it is exactly as exposed as a dart-define while looking like secret management. It also costs an async `await dotenv.load()` before `runApp`, an asset entry that must exist at build time or the build fails, and `dotenv.testLoad(...)` in every test that touches config, where `Env.parse(mode: ..., clientId: ...)` needs nothing. The popularity of the package in Flutter is a habit carried over from backend work, not a property of the platform. Neither mechanism may ever hold the Integration API secret (AGENTS.md).
- **A `.env` read at build time by a script that emits `--dart-define` flags**: legitimate, and it keeps the file out of the bundle, but it is a wrapper around the same two values. `--dart-define-from-file` already does it without a script.

## Consequences

- Every repository has two implementations (mock and live) behind the same domain interface.
- The live path is only checked end-to-end by the human in P7.
- Config values are compile-time constants, so changing one means rebuilding. With two values, one of them a mode switch, that is not a cost worth designing around.
- `Env.parse` rejects an unknown mode, and live mode without a Client ID, at startup rather than at the login screen.
- For a shorter command line, `--dart-define-from-file=<file>.json` takes the same values from one gitignored file, with no package and no asset. The P5 README mentions it after the explicit `--dart-define` form.
- Revisit if config grows past a handful of values or several environments, or if a value must change without a rebuild. The answer then is remote config, not a bundled file.
