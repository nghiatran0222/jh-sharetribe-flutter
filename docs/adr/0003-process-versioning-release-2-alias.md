# 0003. Process versioning: new release-2 alias, release-1 never moves

- Status: Accepted
- Date: 2026-09-20
- Phase: P0 (applied in P1 and P7)

## Context

Sharetribe transaction processes are versioned, and each transaction runs on the version it started on. Aliases (such as `simple-request/release-1`) point to a version, and listing types and the app refer to aliases. There are two ways to ship v2: move `release-1` to version 2, or create a new `release-2` alias. Both work technically. "Editing a live process in place" is a risk a reviewer is explicitly listed to look for (`docs/q-and-a.md`).

## Decision

Push v2 as version 2 and create a **new `simple-request/release-2`** alias. Point the listing type and the app's `Env` default at `release-2`. **`release-1` stays on version 1 and is never moved.**

## Alternatives rejected

- **`update-alias release-1 → version 2`**: this is the common pattern in Sharetribe's docs, and in-flight transactions stay safe either way. But the alias name no longer matches its version, and a reviewer reading the diff sees what looks like an in-place edit.

## Consequences

- The versioning is visible in names: `release-1` = v1, `release-2` = v2.
- Clients choose the version via `processAlias` on `transactions/initiate`, so the Flutter app will switch by changing one constant when the request flow is built (P4b, ADR 0005); until then the alias is selected in Console on the listing type. Re-pointing a listing type in Console only matters if the Sharetribe Web Template is also used (confirm in P7).
- The README and the v2 CHANGELOG must explain that transactions started on v1 keep running on v1.
