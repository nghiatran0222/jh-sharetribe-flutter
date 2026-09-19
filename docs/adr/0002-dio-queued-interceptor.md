# 0002. HTTP client: dio with a QueuedInterceptor for token refresh

- Status: Accepted
- Date: 2026-09-20
- Phase: P0

## Context

Sharetribe access tokens are short-lived. On a 401, the client must use the refresh token to get a new access token and retry the request. When the listings screen fires several requests at once and they all get a 401, a naive client runs several refreshes in parallel. Those race each other, and a rotated refresh token can be invalidated by the losing request. An early draft of the plan used `http`; the analysis doc and `CLAUDE.md` used dio.

## Decision

Use **dio** in `SharetribeClient`, with a **`QueuedInterceptor`** that attaches `Authorization: Bearer`, and on a 401 performs **one** refresh, persists the rotated refresh token, and retries the queued requests.

## Alternatives rejected

- **http + a hand-written wrapper**: works, but the single-flight lock and retry queue have to be built and tested by hand, which is extra code with the same result.
- **Refresh on a timer before expiry**: still needs 401 handling for clock skew and revoked tokens, so it doesn't remove the interceptor.

## Consequences

- Refresh logic lives in exactly one place (an `AGENTS.md` rule).
- Tests inject a `Dio` with a fake `HttpClientAdapter` and must cover: 401 → refresh → retry, parallel 401s → exactly one refresh, and the rotated refresh token being persisted.
- Adds `dio` as a dependency. The `http` package is not used.
