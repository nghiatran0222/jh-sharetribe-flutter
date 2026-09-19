# Plan

---

## Energy / Core Principle

### Principle 1 — Spec is law. 

- Simple-request / simple-request-v2, Marketplace API only, mock-by-default, no Integration secret in the app. 
- Agents implement; they do not renegotiate.

### Principle 2 — The loop is the unit of work. 

- Every agent session is gather → act → verify with a runnable stop condition. 
- “Looks like a login screen” is not done. 
- `flutter test` && `flutter analyze` (plus a mock-mode run) is done.

### Principle 3 — Humans own the live marketplace; agents own the repo. 

- Console, flex-cli login, Stripe, and real users are outside the agent. 
- Code, tests, README, and mock fixtures are inside it.

| Requirement | State now | Agent may close it? |
|--|--|--|
| Sharetribe setup + simple process | Not started — no `sharetribe/` yet | Files yes (P1); publish no — you run flex-cli (P7) |
| Process modification + explanation | Not started | Drafts v2 + CHANGELOG.md (P1); you approve the change |
| Flutter auth | Not started — no `flutter_app/` yet | Yes |
| Fetch + display listings | Not started | Yes |
| Source + README + process note | Brief + docs/ only; no root README | Yes |

The repo today holds only README.md, CLAUDE.md, .gitignore and docs/. Everything below is still to build:

```text
sharetribe/
  simple-request/              # v1 baseline process.edn + templates  (P1)
  simple-request-v2/           # v2 change + CHANGELOG.md             (P1)
  README.md                    # flex-cli create/push/alias steps     (P1)
flutter_app/                   # flutter create                       (P2a)
  lib/
    core/                      # Env, Result, AppError                (P2a)
    data/
      json_api.dart            # data + included denormalizer         (P2a)
      sharetribe/              # SharetribeClient (dio), TokenStore   (P2a)
                               # *_repository.dart live impls         (P2)
      mock/                    # in-memory auth + listings + tx       (P2)
    domain/                    # models + abstract repos              (P2a)
    presentation/              # Cubits + login, listings pages       (P4)
    app.dart                   # BlocProvider / RepositoryProvider    (P4)
  test/                        # json_api, refresh, repos, widgets    (P3/P4)
```

Definition of done (whole assessment)

```
# Agent-verifiable (no live Sharetribe)
cd flutter_app
flutter analyze
flutter test
flutter run --dart-define=SHARETRIBE_MODE=mock

# Human-verifiable (live sandbox)
flex-cli process --path ../sharetribe/simple-request-v2
flutter run --dart-define=SHARETRIBE_MODE=live \
  --dart-define=SHARETRIBE_CLIENT_ID=...
# login with sandbox user → listings render
```

---

## Frequency / Systematic Method

1. Freeze a spec package before any write. One AGENTS.md / CLAUDE.md at the repo root with stack, layers, commands, and forbidden moves.
2. Plan mode first, then one phase per session. Do not ask one agent to “finish the assessment.”
3. TDD on the parse/auth seams; UI last. JSON:API mapping and token refresh are where seniors get scored.
4. Mock is the harness; live is a second verify. Agents must be able to go green with SHARETRIBE_MODE=mock.
5. Human gates are explicit. Anything that needs Console or secrets pauses and waits for you.
6. Reviewer agent after implementer. A second agent that is told to refute, not praise.

Target architecture (do not let the agent redesign this)

```text
presentation  →  Cubit (flutter_bloc)  →  domain repos
                                         ↓
                               mock impl  |  live impl
                                         ↓
                               SharetribeClient (dio + QueuedInterceptor refresh, JSON:API)
                                              ↓
                                    flutter_secure_storage
```

Screens (simple, functional):

| Route | Behavior |
|--|--|
| /login | email/password; error text; signup optional |
| /listings | list title, price, author, image; pull-to-refresh; empty/error; logout |
| /listings/:id (optional) | description + Request using transition/request |

Phase DAG (what runs, in order)
- P0  Harness          AGENTS.md, Makefile, dart-defines, gitignore
- P1  Process spec     v1 baseline + v2 change + CHANGELOG — agent drafts, you approve; publish in P7
- P2a Foundations      flutter create, Env, Result/AppError, JsonApi, SharetribeClient (dio), TokenStore
- P2  Data impl        mock + live Auth/Listing/Transaction repos
- P3  Tests            JSON:API, token refresh, mock auth, listing parse
- P4  Presentation     login + listings (+ optional request)
- P5  README           root README + Flutter setup
- P6  Review           adversarial review vs the brief
- P7  Human live       Console + flex-cli + one live login  [YOU]

P2a, P2 and P3 can be one session. process.edn is frozen once P1 is approved. P4 must not start until flutter test is green on P3. P7 cannot be delegated.

Claude Code vs Grok Build — same plan, different throttle

| Concern | Claude Code | Grok Build |
|--|--|--|
| Start | Plan mode, then default | Plan / this chat, then implement |
| Durable facts | CLAUDE.md | AGENTS.md + CLAUDE.md (same content) |
| Parallel | Task subagents (read-only recon vs implement) | spawn_subagent / workflow phases; worktree isolation if two writers |
| Verify | PostToolUse hook or “run make verify after every change” | Same command in every agent prompt |
| Review | Fresh /review or a new session | review skill or a read-only reviewer subagent |
| Do not | One 4-hour “build everything” chat | One workflow that writes process.edn and Flutter UI in parallel |

Rule: one writer at a time on `flutter_app/lib`. Parallel is only for (a) tests vs docs, or (b) reviewer after writer is done.

What you type vs what the agent types
- You (human, non-delegable)
	1. Sharetribe Console trial, Marketplace ID, Client ID.
	2. flex-cli login + process create/push/alias (commands written to sharetribe/README.md in P1).
	3. One published listing + one customer user in sandbox.
	4. Pass Client ID via --dart-define, never commit it.
	5. Watch a live login once.
- Agent (delegable)
	1. Mock repos, live repos, UI, tests, README, analyze/test green.
	2. Must not: put client secret in Dart, rewrite process.edn after P1 approval, add Stripe, replace BLoC with Provider/Riverpod, swap dio for http, move a live alias, or “improve” the process graph.

---

## Vibration / Practical Application

1. Write the harness file first (5 min, you or a tiny agent session)

```
Put this at AGENTS.md in the repo root (copy into CLAUDE.md):

# Sharetribe Flutter assessment

## Stack
Dart 3 / Flutter, flutter_bloc (Cubit), dio, flutter_secure_storage.
Sharetribe Marketplace API (JSON:API). No official Flutter SDK.

## Architecture
presentation → domain repositories → data (mock | live SharetribeClient)
Do not add a backend. Do not use the Integration API.

## Commands
- test: `cd flutter_app && flutter test`
- lint: `cd flutter_app && flutter analyze`
- run mock: `flutter run --dart-define=SHARETRIBE_MODE=mock`
- run live: `flutter run --dart-define=SHARETRIBE_MODE=live --dart-define=SHARETRIBE_CLIENT_ID=...`

## Rules
- Never commit SHARETRIBE_CLIENT_ID or any client secret.
- Never put Integration API secret in the app.
- Do not edit sharetribe/simple-request*/process.edn unless asked.
- Mock mode is default and must run without network.
- JSON:API parsing stays in data/json_api.dart + Listing.fromJsonApi.
- Token refresh lives only in the dio QueuedInterceptor: one refresh per 401 burst, rotated refresh token persisted.
- Transactions use simple-request/release-2. Never move or edit release-1.
- Result/AppError is the error type. No uncaught throws in repos.
- UI stays simple. Functionality and structure over design.
```

Add `flutter_app/Makefile`:

```
verify:
    flutter analyze
    flutter test
```

2. Session 0 — Plan only (both tools)

Prompt:

```
Read this repo (README.md, AGENTS.md, docs/) only. Do not edit. Produce: (1) gap vs the brief, (2) file-level plan for mock+live repos, login, listings, tests, README, (3) what you will NOT change. Stop.
```

Expected: it should find nothing built yet and order the work P1 → P2a → P2/P3 → P4. If it proposes Provider/Riverpod, http instead of dio, or moving the `release-1` alias, reject the plan.

3. Session 1 — Data + tests (writer, TDD)

Prompt (paste as-is):

```
Implement live and mock repository implementations for Auth, Listing, and Transaction. Do not build UI yet.

Constraints from AGENTS.md. First build the P2a foundations in flutter_app/: Env (SHARETRIBE_MODE, SHARETRIBE_CLIENT_ID), Result/AppError, data/json_api.dart, lib/data/sharetribe/sharetribe_client.dart (dio + QueuedInterceptor refresh), TokenStore (flutter_secure_storage).

Mock: two users (customer@test.com / password123, provider@test.com / password123), three listings with images as URLs, login/signup/restore/logout, fetchListings, requestListing.

Live: password grant scope=user, current user show, listings query with include=author,images, initiate simple-request/release-2 + transition/request.

Tests first, injecting a Dio with a fake HttpClientAdapter. Cover: JSON:API denormalize, 401→refresh→retry, parallel 401s → exactly one refresh, rotated refresh token persisted, mock login failure, listing parse with included author+image.

Done when cd flutter_app && flutter analyze && flutter test exits 0.
Do not touch process.edn. Do not add packages unless required.
```

4. Session 2 — Presentation

Replace the counter `main.dart` with a small app:
- `App` wires Env, TokenStore, repos (mock vs live from Env) via RepositoryProvider, and Cubits via BlocProvider.
- AuthCubit + LoginPage: email, password, error, loading.
- ListingsCubit + ListingsPage: restore session on launch; if no session → login; else list; pull-to-refresh; empty/error; logout.
- Optional ListingDetail with Request (customer note).

flutter_bloc Cubits only (test them with bloc_test). Material 3, no design system.
Update widget tests. `make verify` must stay green.
Mock mode must show listings without network.

5. Session 3 — README (submission artifact)

Root `README.md` must contain:
- What this is (assessment map)
- Prerequisites (Flutter, optional Node/`flex-cli`)
- Sharetribe: create marketplace, publish v1 as `release-1`, push v2, create `release-2`, point the listing type at it, create listing (link to `sharetribe/README.md`)
- Flutter mock run and live run
- Test users
- “Transaction process changes” — ½ page that points at `simple-request-v2/CHANGELOG.md` and restates the why in reviewer English, including why a new `release-2` alias leaves transactions started on v1 untouched
- Security note: Client ID is public; secret never in the app

6. Session 4 — Adversarial review (new agent, read-only)

Review this repo as a hiring bar for Senior Flutter (API + auth + Sharetribe).
Read the brief requirements. For each: pass / fail / gap, with file evidence.
Hunt: secrets in git, Integration API in Flutter, JSON parsed as plain maps in widgets, session not restored, process edited in place, counter UI left behind, tests still the counter test, README that cannot be followed.
Do not fix. List ordered fixes.

Then a short fix session for whatever it found.

7. Human live gate

```bash
flex-cli process --path sharetribe/simple-request-v2
flex-cli process push --process simple-request --path sharetribe/simple-request-v2 -m $MID
flex-cli process create-alias --process simple-request --alias release-2 --version 2 -m $MID
```

`release-1` stays on version 1; it is never moved. In Console, point the listing type's transaction process at `simple-request/release-2`.

Then run live, log in, confirm listings. If listings are empty, the failure is gather (no published listing in Console), not Flutter.

8. Grok Build workflow shape (if you want orchestration)

Do not parallelize writers on `lib/`. A safe workflow is sequential phases:

1. `agent` implement data+tests (`execute`) → fail the run if verify fails
2. `agent` implement UI (`execute`) → same verify
3. `agent` README (`read-write`)
4. `agent` reviewer (`read-only`) → `complete` with pass/fail vs brief

Insert `await_user` before any `flex-cli` or live credential step.

9. Claude Code driving rules for this repo

- Start in plan, implement in default, never bypass for the first pass.
- After every file batch: flutter analyze && flutter test.
- If a loop fails, diagnose phase: wrong file (gather), wrong Sharetribe path (act), tests not run (verify). Do not re-prompt “try again.”
- Keep the Result / AppError / JsonApi types from P2a. A common agent failure is introducing Either or throwing Exception in widgets.
- If the agent wants Provider, Riverpod, http, go_router, freezed — no. The stack is flutter_bloc + dio.

Copy-paste: one-shot “finish it” prompt (only after Sessions 0–1 plan is accepted)

Use this only if you will sit with the agent and watch verify:

```
Sharetribe process v1/v2 (P1) is approved. Do not edit process.edn.
Foundations, mock+live repos and their tests (Session 1) are merged; main.dart is still the flutter create counter.

Build: login + listings UI with Cubits, widget tests, root README.
Follow AGENTS.md. After every change run flutter analyze && flutter test.
Stop when mock run would show listings and README explains process v2 + setup.
Never commit secrets.
```

Failure modes to watch (agent-specific)

| Symptom | Phase | Fix |
|--|--|--|
| Invents `flex-sdk` Dart package | Gather | Point at existing `SharetribeClient` |
| Puts client secret in `env.dart` | Act | Client ID only; secret is Console-only |
| Rewrites process to add Stripe | Act | Out of scope; CHANGELOG explains why |
| Parses listings in the widget | Act | Use `JsonApi.listingsFromDocument` |
| Declares done, counter test still there | Verify | `make verify` is the stop condition |
| “I would run flex-cli for you” and stalls | Gather | Human gate — you run Console |

Time box

| Work | Who | Time |
|--|--|--|
| Harness + plan | You + agent | 20 min |
| Data + tests | Agent | 45–90 min |
| UI + widget tests | Agent | 45–90 min |
| README | Agent | 20 min |
| Review + fix | Agent pair | 30 min |
| Live Console + smoke | You | 30–60 min |

Call it half a day if mock-first; a day if you also prove a live transaction.

---

## Lock so the agent cannot drift

- Layout: repo root holds sharetribe/ and flutter_app/
- Process alias: simple-request/release-2 for new transactions (Env default); release-1 stays on v1
- Auth: password grant + refresh + restore session
- HTTP: dio + QueuedInterceptor (single-flight refresh on 401)
- Listings query: include=author,images
- State management: BLoC — flutter_bloc Cubits
- Default run: mock
- Stretch: Request button → transition/request (shows you understood the process without building a full inbox)
