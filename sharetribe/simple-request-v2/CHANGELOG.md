# simple-request v2: provider must accept

## What changed

v1 confirms a request the moment the customer sends it. v2 adds a **provider decision step** (request-to-book): a new request waits in `state/pending` until the provider accepts or declines.

```text
v1   (initial) --request/customer--> accepted --complete/provider--> completed
                                        \--cancel/customer, operator-cancel/operator--> canceled

v2   (initial) --request/customer--> pending --accept/provider--> accepted --complete/provider--> completed
                                       |  |  \--decline/provider-->  declined        \--cancel, operator-cancel--> canceled
                                       |  \--withdraw/customer--> withdrawn
                                       \--expire/(automatic, 3 days)--> expired
```

| | v1 | v2 |
|--|--|--|
| New states | — | `pending`, `declined`, `withdrawn`, `expired` |
| New transitions | — | `accept` (provider), `decline` (provider), `withdraw` (customer), `expire` (automatic, 3 days after entering `pending`) |
| `transition/request` | lands in `accepted` | lands in `pending` (same name, same actor, same params) |
| From `accepted` onward | `complete`, `cancel`, `operator-cancel` | unchanged |
| New emails | — | request accepted / declined / withdrawn / expired; the new-request email now asks the provider to respond |

## Why

- **It changes who decides.** In v1 the customer alone commits both sides. v2 gives the provider an explicit accept/decline, which is how most service and rental marketplaces work.
- **Nothing gets stuck.** Every new branch ends: the provider answers, the customer withdraws, or the request expires after 3 days (`:at` = first entry into `pending` + `P3D`).
- **None of it is privileged.** `accept` and `decline` are ordinary provider transitions, so the Marketplace API can call them with the provider's own token. No backend and no Integration API secret are needed.
- **The client change is minimal.** `transition/request` keeps its name and parameters, so the Flutter app only switches `processAlias` from `release-1` to `release-2`.
- **Still no payment.** No Stripe actions, in line with the assessment scope (ADR 0008).

## Versioning (ADR 0003)

v2 is pushed as **version 2** of the `simple-request` process, behind a **new alias `release-2`**. `release-1` stays on version 1. Sharetribe pins every transaction to the process version it started on, so requests created under v1 finish under v1 rules; only new requests initiated with `simple-request/release-2` use the accept step.

Full decision record: [ADR 0007](../../docs/adr/0007-v2-provider-accept.md).
