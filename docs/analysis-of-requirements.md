# Analysis of Requirements

---

## Energy / Core Principle

Sharetribe is a headless marketplace backend. Your job is to own the rules of a deal (transaction process) and a thin Flutter client that authenticates and reads listings.

### Principle 1 — Process is the product. 

- Listings, users, and payments only matter inside a versioned state machine (`process.edn`). 
- Changing that machine is the senior-level signal.

### Principle 2 — Two APIs, two trust levels. 

- Marketplace API = user token (login, browse, start a deal). 
- Integration API = client secret (privileged transitions, operator actions). 
- Secrets never go in Flutter.

### Principle 3 — Structure beats screens. 

- UI can be simple. 
- Focus layers, token handling, JSON:API parsing, and a README a can run.

---

## Frequency / Systematic Method

|  | Requirement | What “done” looks like | What is scoring |
|--|--|--|--|
| 1 | Sharetribe setup | Trial marketplace in Console + sandbox | Can stand up Flex, not Sharetribe Go |
| 2 | Simple transaction process | One process alias (e.g. purchase or booking) assigned to a listing type | Understand states, transitions, actors |
| 3 | Modify the process | New version (…/release-2), not an in-place edit of a live alias | Versioning, privileged vs actor transitions, a written rationale |
| 4 | Flutter auth | Email/password login via OAuth2, token stored securely, session | OAuth2, refresh, no secrets in the app restore |
| 5 | Fetch listings | Authenticated (or public) GET /v1/listings with JSON:API denormalization | Models, error/empty/loading, not a dump of raw JSON |
| 6 | README + process note | Clone → env vars → run; ½–1 page on the process change | Communication as a senior |

There is no official Flutter/Dart SDK. The correct senior move is REST (dio or http) against:
- https://flex-api.sharetribe.com/v1/auth/token (password + refresh grants)
- https://flex-api.sharetribe.com/v1/listings (JSON:API)

Six methods to execute it
1. Create a Flex sandbox in Sharetribe Console. Capture Client ID for the app; keep Client Secret off-device.
2. Clone a default process (default-purchase or default-booking) → edit → publish a new release.
3. Make one load-bearing change, not cosmetics: extra state, extra actor transition, privileged operator step, or skip a default step (e.g. auto-accept, extra review, admin approve).
4. Flutter: clean layers — data (API + token store) / domain (models, auth/listing use cases) / presentation (login + list). Riverpod or Bloc is enough.
5. Auth loop — login → persist access + refresh tokens (flutter_secure_storage) → attach Authorization: Bearer → refresh on 401 once → logout.
6. Listings loop — include=author,images → map data + included → title, price, image, author → loading / empty / error.

Transaction process (what “modify” means)
1. A process is a finite-state machine:
	- States: inquiry, pending, accepted, delivered, canceled, reviewed, …
	- Transitions: named moves with from / to, an actor (customer / provider / operator), actions (Stripe, emails, availability), optional privileged: true
	- Versioning: live listings pin an alias like default-purchase/release-1. You never mutate that in place; you ship release-2 and re-point the listing type.
2. A reviewer-friendly modification (pick one):
	- Add state/pending-provider-approval + transition/provider-accept (request-to-book instead of instant).
	- Add a privileged transition/operator-approve so the deal cannot complete without an operator.
	- Drop Stripe from a demo path and use a no-payment “confirm” transition (only if they do not require payments).
	- Add a post-delivery transition/customer-confirm-receipt before reviews open.

Then write why: actor, extra state, privileged or not, and how existing transactions stay on the old release.

--- 

## Vibration / Practical Application

### Recommended scope (if they give no extra spec)

#### Sharetribe

- Flex trial, one listing type, 2–3 sandbox listings, 2 users (customer + provider).
- Start from default-purchase or default-booking.
- Modification: request-to-book — customer initiates → provider must accept → then payment/confirm. New process version. Short write-up in README.

#### Flutter (functionality, not design)

- Screens: Login, Listing list (optional: listing detail).
- Auth: login + logout + restore session on launch. Signup optional.
- Listings: title, price, first image, author. Pull-to-refresh. Empty and error states.
- No Stripe checkout in the app unless they insist. Process lives in Console; the app proves it can talk to the marketplace.

#### Repo layout

```text
/
  README.md
  sharetribe/
    process.edn          # or exported JSON + notes
    PROCESS_CHANGES.md   # what / why / versioning
  flutter_app/
    lib/
      data/              # api client, token storage, dto
      domain/            # listing, user, failures
      presentation/      # login, listings
```

### Nine applications (do these, in order)

1. Confirm Flex trial + Client ID exist before writing Dart.
2. Export the stock process so the diff is visible.
3. Change one workflow rule; bump the release; assign it to the listing type.
4. Create sandbox users and listings that use that process.
5. Flutter: env-based Client ID (--dart-define or .env, gitignored).
6. Implement password grant + secure storage + refresh-on-401.
7. Parse JSON:API properly (data + included); do not hand-roll a one-off map in the widget.
8. Show listings only after a valid session (unless we agree public query is in scope).
9. README: Console steps, env vars, flutter run, test user, and the process explanation.

### Definition of done (runnable)

- Sharetribe sandbox: listing type uses your-process/release-2.
- Flutter run with Client ID → login with sandbox user → list shows titles/prices.
- README lets a stranger reproduce both in under 30 minutes.