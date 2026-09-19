# Q&A of Requirements

Need answers before building.
These are the gaps in the brief.

## Blockers

1. Do you already have a Sharetribe Flex Console marketplace (Client ID / sandbox), or should the submission assume a new trial from scratch? Flex trial is required; Go cannot satisfy “modify the transaction process.”
2. Marketplace type? Product purchase, time-based booking, or hourly service? This picks the default process.
3. What modification do you want, or should I choose one? The brief says “make modifications” but not which. I recommend request-to-book (provider accept) unless you have a real workflow (admin approve, no payment, extra review, etc.).
4. Must the Flutter app start a transaction (checkout), or is login + fetch listings enough? The written Flutter scope is only auth + listings. Building checkout is extra unless expect it.

---

## Important

1. Auth surface: login only, or also signup + forgot-password? I recommend login + logout + session restore.
2. Listings visibility: after login only, or public browse with anonymous token (client_credentials)?
3. Payments: Stripe test keys in the process, or a no-payment demo process? Stripe makes the process “real” but is heavier than the Flutter brief.
4. Target: Android, iOS, or both or Web? Any required Flutter/Dart version?
5. State management preference: Riverpod, Bloc, or Provider? I recommend BLoC.
6. Submission form: GitHub repo, zip, or both? Can sandbox credentials go in the README (test user only, never the Integration API secret)?

---

## Non-blocking (I’ll decide if you don’t)

1. Architecture: data / domain / presentation.
2. Networking: dio + interceptor for refresh.
3. UI: Material 3, no design system.
4. Tests: unit tests for JSON:API mapping + auth token refresh; widget tests only if time allows.

---

## Working decisions (assumed by docs/plan.md until answered)

A row can only be *Decided* once it links to an ADR in `docs/adr/`.

| Question | Working answer | Status | ADR |
|--|--|--|--|
| Blocker 1 — Marketplace | New Flex trial from scratch; you run Console + flex-cli (P7) | Assumed | — |
| Blocker 2 — Marketplace type | Request-based, no payment: custom `simple-request` process | Assumed | — |
| Blocker 3 — Modification | v2 adds a real step (recommended: provider-accept, request-to-book); shipped as new `release-2` alias, `release-1` untouched | Assumed — confirm the exact change in P1 | [0003](adr/0003-process-versioning-release-2-alias.md) (alias); 0007 in P1 (change) |
| Blocker 4 — Transaction in app | Not required. Login + listings; Request button is stretch (P4b) | Assumed | [0005](adr/0005-request-flow-as-stretch.md) |
| Important 1 — Auth surface | Login + logout + session restore; signup optional | Assumed | — |
| Important 2 — Listings visibility | After login only | Assumed | — |
| Important 3 — Payments | No Stripe | Assumed | — |
| Important 4 — Targets / versions | Flutter 3.47.x stable; platforms not decided | Open | — |
| Important 5 — State management | BLoC (flutter_bloc Cubits) | Decided | [0001](adr/0001-flutter-bloc-cubits.md) |
| Important 6 — Submission form | Not decided | Open | — |
| Non-blocking — Networking | dio + QueuedInterceptor (single-flight refresh) | Decided | [0002](adr/0002-dio-queued-interceptor.md) |
| Non-blocking — Run modes | Mock is default for dev/tests; README leads with the live run | Decided | [0004](adr/0004-mock-default-live-first-readme.md) |

---

## Risks will notice

1. Putting the Integration API secret in Flutter.
2. Editing a process in place instead of a new release.
3. Treating Sharetribe responses as plain JSON instead of JSON:API.
4. Login that does not persist/restore the session.
5. A process change that is only a renamed label, with no new state/actor/privilege.
6. README that says “set up Sharetribe” with no Console clicks, process alias, or test user.