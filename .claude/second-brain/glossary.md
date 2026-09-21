# Glossary

The shared words for `process.edn`, Dart code, tests and the README. Use these names in code; do not invent synonyms. Process names are used verbatim (ADR 0011).

## Contexts

| Context | Owns | In the app |
|--|--|--|
| Identity | users, login, tokens | `AuthRepository`, `TokenStore` |
| Catalog | listings, images, authors | `ListingRepository` |
| Transactions | the `simple-request` process | `TransactionRepository` (mock + live), `RequestCubit` |

Sharetribe owns the rules of all three. The app is a client, and `data/json_api.dart` + `fromJsonApi` is the only translation from Sharetribe's shapes to domain models.

## Marketplace

- **Marketplace**: one Sharetribe Flex environment (the trial or test marketplace), managed in Console.
- **User**: a marketplace account. The same user can be a customer on one transaction and a provider on another.
- **Customer**: the user who requests a listing (`:actor.role/customer`).
- **Provider**: the user who owns the listing and answers requests (`:actor.role/provider`).
- **Author**: the JSON:API relationship from a listing to its provider (`include=author`). In domain code, author = provider.
- **Operator**: the marketplace admin, acting through Console (`:actor.role/operator`). Never the app.
- **Listing**: something a provider offers: title, description, price, images, author.
- **Price**: Sharetribe money: an amount in minor units (cents) plus a currency. Never a float.
- **Image variant**: a named, server-sized version of an image (e.g. `landscape-crop`), requested with `fields.image`. A missing variant is a null image, not an error.

## Transactions

- **Transaction process**: the state machine in `process.edn` that Sharetribe runs. Ours is `simple-request`, with no payment (ADR 0008).
- **Process version**: an immutable pushed copy of a process. v1 = version 1, v2 = version 2.
- **Process alias**: a named pointer to a version: `simple-request/release-1` → v1 (never moved), `simple-request/release-2` → v2 (ADR 0003).
- **Transaction**: one run of a process between a customer and a provider for a listing. It stays on the version it started on.
- **Transition**: a named step between states, taken by one actor, e.g. `transition/request`, `transition/accept`.
- **State**: where a transaction is, e.g. `state/pending`, `state/accepted`.
- **Request**: a customer starting a transaction with `transition/request` on `transactions/initiate`. In v2 it lands in `pending`; in v1 it lands in `accepted`.
- **Pending** (v2): waiting for the provider. It ends by `accept`, `decline`, `withdraw` (customer), or `expire` (automatic, 3 days).

## Auth and APIs

- **Marketplace API**: the API for end users, called with the public Client ID and a user token. The only API the app calls.
- **Integration API**: the trusted back-office API that needs the Client Secret. Never in the app or the repo.
- **Client ID**: public identifier of the app; passed as `SHARETRIBE_CLIENT_ID` in live mode. Not committed.
- **User token**: access token + refresh token from `POST /v1/auth/token` (`password` grant, `scope=user`). Stored in `TokenStore`.
- **Refresh**: exchanging the refresh token for new tokens after a 401. Happens once per burst, only in the dio `QueuedInterceptor`, and the rotated refresh token is saved.
- **Session restore**: reading stored tokens on launch so a logged-in user goes straight to listings.

## App

- **Mock mode / live mode**: `SHARETRIBE_MODE=mock` (default, offline fixtures) or `live` (real Marketplace API). See ADR 0004.
- **Repository**: a domain interface (`domain/`) with one mock and one live implementation (`data/`).
- **AppError**: the domain error in domain terms (e.g. invalid credentials, network, unauthorized), returned in a `Result`, never thrown out of a repository.
