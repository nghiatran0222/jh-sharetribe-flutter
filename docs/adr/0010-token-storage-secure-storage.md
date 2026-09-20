# 0010. Token storage: flutter_secure_storage behind a TokenStore interface

- Status: Accepted
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
- `AppDependencies.fromEnv` (P4) is the only place that builds a store. It uses `SecureTokenStore` in **both** modes, so mock mode restores a session across launches exactly as live mode does, and the difference between the modes stays limited to the repositories. `test/app_mock_test.dart` passes an `InMemoryTokenStore` through the `tokenStore` override, because widget tests have no platform channels.
- flutter_secure_storage 11 needed no `minSdk` override: `android/app/build.gradle.kts` still uses `flutter.minSdkVersion` and the debug APK builds (checked 2026-09-21 against Android SDK 36.1.0). iOS Keychain needs no entitlement for this use. The Keystore path has not been exercised at runtime yet — the E2E suite can run on Android (it converts the surface before screenshots), but that run has not been completed.

## Status history

- Proposed when written; **Accepted 2026-09-20**. The E2E suite (ADR 0016) exercises the real `SecureTokenStore` on a simulator, so the decision is verified, not just described.
