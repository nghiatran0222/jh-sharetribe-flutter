# 0015. No OpenAPI codegen; tested fixtures are the API contract

- Status: Accepted
- Date: 2026-09-20
- Phase: P0 follow-up (applied in P2a–P3 and P7)

## Context

OpenAPI could, in principle, generate a typed Dart client for the Marketplace API. Sharetribe's Marketplace API reference links no OpenAPI/Swagger file or other machine-readable definition, and its only official SDK is JavaScript (`flex-sdk-js`); a third-party aggregator claims specs exist, but Sharetribe does not confirm it. So a spec would have to be written by hand. The usual generators (`openapi-generator` `dart-dio` / `dart`) emit `built_value` or `json_serializable` models through `build_runner`, which ADR 0011 (hand-written models), AGENTS.md (no freezed) and the guard hook (ADR 0014) exclude. JSON:API responses also generate poorly: `included` mixes resource types linked by `relationships`, so a generated client still needs `json_api.dart` to denormalize. The app calls three endpoints: `POST /v1/auth/token`, `GET /v1/current_user/show`, `GET /v1/listings/query`.

## Decision

Do not use OpenAPI, for code generation or as a documentation spec. The API contract is the set of **tested fixtures**: JSON:API responses shaped like Sharetribe's reference examples (Session 1), plus one real sandbox `listings/query` response captured in P7 (personal data removed) and parsed by a test.

## Alternatives rejected

- **Client generated from an official spec**: none is published.
- **Hand-written spec + generated client**: hours for three endpoints; brings `build_runner` codegen; duplicates the dio client and `QueuedInterceptor` (ADR 0002); still needs the JSON:API denormalizer.
- **Hand-written spec as documentation only**: nothing enforces it, it can drift from both the API and the code, and it would be a second, unofficial source beside Sharetribe's reference. The endpoint list in AGENTS.md (Architecture) and the glossary already describe the subset.

## Consequences

- `json_api.dart` and `Listing.fromJsonApi` stay the only mapping code (ADR 0011); their tests are the contract check.
- P7 adds a real-response fixture test, so the mock and live shapes cannot silently diverge.
- No OpenAPI tooling (`openapi-generator`, `swagger_parser`, `openapi_generator_annotations`, …) is added; P6 checks that no generated files appear in `flutter_app/`.
- The P5 README "Key decisions" can state: "No OpenAPI: Sharetribe publishes none; JSON:API mapping is hand-written and tested."
- Revisit only if Sharetribe publishes an official spec; that would be a new ADR.
