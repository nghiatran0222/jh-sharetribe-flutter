# 0004. Run modes: mock is the default for dev and tests; the README leads with live

- Status: Accepted
- Date: 2026-09-20
- Phase: P0 (applied in P2a and P5)

## Context

Agents have no Sharetribe credentials, and a device-free `make verify` is the definition of done, so the app must work without the network. But the brief asks for an app that "authenticates with Sharetribe", and a reviewer who only sees mock data could conclude there is no real integration.

## Decision

`SHARETRIBE_MODE` (a dart-define) selects `mock` or `live`, and defaults to **`mock`**. Tests and the full-app `test/app_mock_test.dart` run in mock mode. The root README presents the **live run first** and mock as the offline fallback.

## Alternatives rejected

- **Live by default**: tests and agents would need credentials and the network, so `make verify` couldn't run on its own.
- **Mock only**: fails the brief.
- **A recorded-HTTP fixture layer instead of mock repositories**: more realistic, but a bigger build for a 3-day assessment. Unit tests already cover the live client with a fake `HttpClientAdapter`.

## Consequences

- Every repository has two implementations (mock and live) behind the same domain interface.
- The live path is only checked end-to-end by the human in P7.
