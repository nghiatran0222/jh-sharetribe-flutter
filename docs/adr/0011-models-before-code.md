# 0011. Process and domain models come before code

- Status: Accepted
- Date: 2026-09-20
- Phase: P1 (process model), P2a–P2 (domain model); checked in P6

## Context

The system has two models. On the server, the transaction process in `process.edn` is a state machine (states, transitions, actors, actions) that Sharetribe executes as written. In the app, the domain models (`Listing`, `User`) and the abstract repositories are the contract that the Cubits, the mock repos and the live repos all depend on. If code is written first and the models are backfilled afterwards, the mock and live repos drift apart, transition names get invented in the app instead of taken from the process, and raw JSON:API maps leak into widgets.

## Decision

Models are written, and checked, before the code that depends on them. The process model (`process.edn`, validated by `scripts/check_process.py` and later `flex-cli process`) comes before any app code that calls a transition. In each session, the `domain/` models and abstract repositories come before the mock and live implementations. The app uses the process model's names exactly (`transition/request`, `simple-request/release-2`) and never redefines them.

## Alternatives rejected

- **Code first, extract models later**: fast for a single implementation, but this app has two (mock and live, ADR 0004), and without a shared contract they diverge.
- **Generate Dart code from the process or from a schema**: there is no official Dart SDK or codegen for Sharetribe, and the stack forbids freezed. Two hand-written models are small enough to keep in sync by review.

## Consequences

- P1 is the model-driven phase, and it is frozen: any change to the process is a new process version plus an ADR (ADR 0003), never an edit to the model in place.
- Session 1 (P2a–P3) writes `domain/` first. Mock and live repos implement the same interface, and `Listing.fromJsonApi` is the only place JSON:API is turned into a model.
- P6 review checks that the code matches the models: transition names, the process alias, and that v1 is untouched.
- Hand-written models add a small sync cost: a renamed transition must be changed in both `process.edn` (as a new version) and the app.
