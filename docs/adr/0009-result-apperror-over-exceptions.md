# 0009. Repositories return Result/AppError instead of throwing

- Status: Proposed
- Date: 2026-09-20
- Phase: P2a

## Context

The Cubits (P4) need to show a message for every failure: wrong password, no network, expired session, a server error, or a response with an unexpected shape. The failures start as dio and parsing exceptions in the data layer. If repositories let those throw, every Cubit needs its own `try/catch` and has to know about `DioException`. One missed catch is an uncaught exception, and data-layer types leak into the presentation layer. AGENTS.md already says "No uncaught throws in repositories" but did not name the type.

## Decision

Every repository method returns `Future<Result<T>>` (`core/result.dart`: sealed `Ok<T>` / `Err<T>`). `Err` carries a sealed `AppError` (`core/app_error.dart`: `InvalidCredentials`, `EmailTaken`, `Unauthorized`, `NetworkError`, `ServerError(statusCode)`, `UnexpectedError(detail)`), each with a user-safe `message`. Live repositories wrap their bodies in `guard()` (`data/sharetribe/guard.dart`), which maps `DioException`, `FormatException` and anything else to an `AppError`.

## Alternatives rejected

- **Throw typed exceptions and catch in Cubits**: the compiler cannot check that callers catch them. Each Cubit repeats the mapping.
- **fpdart / dartz `Either`**: adds a package for two small classes. AGENTS.md says to add packages only when required.
- **Return null on failure**: loses the reason, so the UI cannot tell "wrong password" from "offline".

## Consequences

- Cubits use an exhaustive `switch` on `Result` and `AppError`. A new error type is a compile error until it is handled.
- `SharetribeClient` and `JsonApiDocument` may still throw. Only repositories must not, and `guard()` is the boundary.
- Tests check the error type with `isA<InvalidCredentials>()` and similar matchers, not exception matchers.
- Mapping lives in `appErrorFromDio`. A 401 that survives the refresh becomes `Unauthorized`. The token endpoint's 400/401 on login becomes `InvalidCredentials`, and a 409 on sign-up becomes `EmailTaken`.
