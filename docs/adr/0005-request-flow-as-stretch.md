# 0005. Scope: the in-app request flow is stretch work (P4b)

- Status: Accepted (revisit if the reviewer requires checkout; `docs/q-and-a.md` Blocker 4)
- Date: 2026-09-20
- Phase: P0

## Context

The brief's Flutter scope is authentication plus fetching and displaying listings. An early plan draft required a Transaction repository and `requestListing` in Session 1, while its lock section called the Request button a stretch goal.

## Decision

The Transaction repository and the listing-detail Request button (initiating `transition/request` on `simple-request/release-2`) are **stretch work in phase P4b**, started only after P4 is green.

## Alternatives rejected

- **Required in Session 1**: widens the first session and delays a green `make verify` for work the brief doesn't ask for.
- **Drop it entirely**: loses a cheap way to show the app understands the process.

## Consequences

- Sessions 1 and 2 cover Auth and Listing only.
- If the reviewer answers that checkout is required, supersede this ADR and move P4b into the main path.
