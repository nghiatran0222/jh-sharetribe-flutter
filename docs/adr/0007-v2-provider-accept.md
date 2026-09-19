# 0007. Process change: v2 adds a provider-accept step (request-to-book)

- Status: Accepted
- Date: 2026-09-20
- Phase: P1

## Context

The brief asks for a change to the transaction process, with an explanation. A reviewer is expected to reject a cosmetic change, such as a renamed label (`docs/q-and-a.md`, "Risks"). The change should add real behavior, stay free of payments, and be callable from the Flutter app with a user token.

## Decision

v1 (`simple-request`) confirms a request instantly. **v2 puts new requests in `state/pending`**, with provider `accept` and `decline`, a customer `withdraw`, and an automatic `expire` after 3 days. Everything from `state/accepted` onward is unchanged, and `transition/request` keeps its name and parameters. Details: `sharetribe/simple-request-v2/CHANGELOG.md`.

## Alternatives rejected

- **Privileged operator approval step**: shows off `:privileged? true`, but privileged transitions need the Integration API (a trusted server). Under ADR 0004 and the no-backend rule, the app could never call it.
- **Customer confirms receipt before completion**: real, but a weaker signal. It only adds one step at the end of the flow, with no new decision-maker.
- **Add Stripe payment**: out of scope (no-payment decision, ADR 0008), and heavy for a 3-day brief.

## Consequences

- New states `pending`, `declined`, `withdrawn`, `expired`, and four new emails.
- The app's only change is `processAlias` → `simple-request/release-2` (ADR 0003).
- `transition/expire` guarantees no request stays pending forever.
- The provider needs a way to accept. The Flutter app doesn't build a provider inbox (out of scope), so in P7 the accept step is exercised through Console or the API with the provider's token.
