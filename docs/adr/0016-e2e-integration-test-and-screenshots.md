# 0016. E2E on a simulator in mock mode, and screenshots from the same run

- Status: Proposed
- Date: 2026-09-20
- Phase: P4 follow-up (after P5)

## Context

`make verify` runs 66 tests without a device or a network, and `test/app_mock_test.dart` drives the whole app in mock mode. But every one of those tests injects an `InMemoryTokenStore`, so `SecureTokenStore` — the flutter_secure_storage code that holds the refresh token in Keychain or Keystore (ADR 0010) — had never executed. Nothing proved that the app restores a session from real device storage, which is the one behavior a reviewer is most likely to try by hand. Separately, the repo had no visual evidence at all: no screenshot showed that the login and listings screens render as intended.

## Decision

Add an `integration_test` suite (`integration_test/app_test.dart`) that runs the real `App` on a simulator or device in **mock mode**, exercising the real `SecureTokenStore`, and take screenshots from that same run through `flutter drive` with `test_driver/integration_test.dart`, writing PNGs to `docs/screenshots/`. The suite stays **out of `make verify`**, which must remain device-free, and runs from a separate `make e2e` target.

## Alternatives rejected

- **Golden tests**: they would give images inside `make verify`, but they are brittle across Flutter versions and font rendering, and a golden that fails on a reviewer's machine looks worse than no golden. They also would not touch secure storage.
- **Screenshots taken by hand from a running simulator**: no test value, and they go stale silently. Generating them from the E2E run means an out-of-date screenshot implies a failing test.
- **E2E against the live Marketplace API**: real credentials, real network and sandbox data that changes, so it is flaky by construction. Live verification stays a human step (P7).
- **Putting the E2E suite in `make verify`**: it needs a booted device, so a reviewer without one could not reach the definition of done.

## Consequences

- Two new dev dependencies from the Flutter SDK: `integration_test` and `flutter_driver`. Neither ships in the app.
- `flutter test` still runs only `test/`, so `make verify` is unchanged and stays device-free.
- The E2E suite is the only test covering Keychain/Keystore and session restore across a relaunch. If flutter_secure_storage breaks on a platform, this is what catches it.
- Screenshots in `docs/screenshots/` are build output committed on purpose: they are the README's visual evidence, and regenerating them is one command.
- On Android, `binding.convertFlutterSurfaceToImage()` is required before `takeScreenshot`; the current run targets an iOS simulator, where it is not.
- `pumpAndSettle` cannot be used in this suite, because a `CircularProgressIndicator` never stops animating. The tests pump real frames until a finder matches, with a timeout.
