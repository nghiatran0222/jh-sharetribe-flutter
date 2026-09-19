# 0008. v1 baseline: hand-written minimal process, no payment

- Status: Accepted
- Date: 2026-09-20
- Phase: P1

## Context

v1 needs a starting process for the v2 change to diff against. Sharetribe's built-in processes (`default-purchase`, `default-booking`) include Stripe actions, dozens of states and a large set of email templates. The assessment scope is login plus listings, with no payment (`docs/q-and-a.md`, Important 3).

## Decision

Hand-write a **minimal no-payment v1**, `sharetribe/simple-request/`: 4 transitions (request, complete, cancel, operator-cancel), 3 states, and 3 plain email templates. It follows the format of Sharetribe's `example-processes` repo (`:format :v3`, and templates stored as `templates/<name>/<name>-html.html` + `<name>-subject.txt`).

## Alternatives rejected

- **`flex-cli process pull` of a default process, then trim it**: needs marketplace credentials before any code exists, and trimming Stripe out of `default-purchase` produces a diff that mostly deletes payment steps, which hides the actual change.
- **Use `default-inquiry` as v1**: it has a single transition, so there's no flow for the v2 change to modify.

## Consequences

- The v1→v2 diff shows only the new decision step.
- The templates are plain Handlebars without the web template's translation assets, so they read as functional rather than branded.
- The files can't be validated without `flex-cli`. `scripts/check_process.py` checks the structure offline; `flex-cli process --path` in P7 is the real check, and the plan budgets one fix-up round.
