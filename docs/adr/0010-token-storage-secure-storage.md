# 0010. Token storage: flutter_secure_storage behind a TokenStore interface

- Status: Proposed
- Date: 2026-09-20
- Phase: P2a

## Context

The user token (access token + refresh token) must survive app restarts so the session can be restored on launch (q-and-a Important 1). The refresh token grants long-lived access to the user's account, so it must not sit in plain `SharedPreferences`. The refresh interceptor (ADR 0002) must save the rotated refresh token, the mock repositories need somewhere to keep a fake session, and unit and widget tests run without platform channels, so `flutter_secure_storage` does not work there.

## Decision

Define an abstract `TokenStore` (`read` / `save` / `clear` of `AuthTokens`) in `data/sharetribe/token_store.dart`. `SecureTokenStore` stores the two tokens with `flutter_secure_storage` (iOS Keychain, Android Keystore-backed encryption) for real runs, and `InMemoryTokenStore` is used by tests. Only the access and refresh tokens are stored. The user profile is not stored; it is fetched again with `current_user/show` when the session is restored.

## Alternatives rejected

- **SharedPreferences**: stores the refresh token in plain text.
- **Access token only, in memory**: no session restore; the user logs in on every launch.
- **Store the user profile too**: stale data and more personal data at rest; `current_user/show` also proves the token still works.

## Consequences

- `AuthInterceptor`, `LiveAuthRepository` and the mock repositories depend on the `TokenStore` interface only.
- Logout clears the store before the best-effort revoke call, so logout works offline.
- A refresh token rejected by the server (400/401) clears the store; the next session restore returns no user.
- `App` wiring (P4) chooses the store: `SecureTokenStore` in live mode. Mock-mode wiring is decided in P4. `test/app_mock_test.dart` must use `InMemoryTokenStore`.
- Android `minSdk` and iOS Keychain requirements come with flutter_secure_storage 11; the README (P5) notes them if the build needs changes.
