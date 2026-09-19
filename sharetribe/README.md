# Sharetribe transaction process

| Folder | Process version | Alias | Behavior |
|--|--|--|--|
| `simple-request/` | 1 | `simple-request/release-1` | Request is confirmed instantly |
| `simple-request-v2/` | 2 | `simple-request/release-2` | Provider must accept or decline; unanswered requests expire after 3 days |

What changed and why: [`simple-request-v2/CHANGELOG.md`](simple-request-v2/CHANGELOG.md). No payment is involved in either version.

## Offline check (no credentials)

```bash
python3 scripts/check_process.py sharetribe/simple-request sharetribe/simple-request-v2
```

This checks structure only (states reachable, actors, notifications, template files). The real validator is `flex-cli`, below.

## Publish (human step, needs Console access)

Prerequisites: a Sharetribe marketplace (dev environment), Node.js, and the CLI: `npm install -g flex-cli`. Run these from the repo root.

```bash
export MID=<your-marketplace-id>
flex-cli login

# 1. Validate / describe both versions locally
flex-cli process --path sharetribe/simple-request
flex-cli process --path sharetribe/simple-request-v2

# 2. First publish: v1 becomes version 1 behind release-1
flex-cli process create --process simple-request --path sharetribe/simple-request -m $MID
flex-cli process create-alias --process simple-request --alias release-1 --version 1 -m $MID

# 3. The change: v2 becomes version 2 behind a new release-2 (release-1 is never moved)
flex-cli process push --process simple-request --path sharetribe/simple-request-v2 -m $MID
flex-cli process create-alias --process simple-request --alias release-2 --version 2 -m $MID

# 4. Confirm: two versions, two aliases
flex-cli process list --process simple-request -m $MID
```

## How a transaction picks the version

A client picks the process when it initiates a transaction: the Marketplace API call `transactions/initiate` takes `processAlias`. The Flutter app sends `simple-request/release-2` (its `Env` default) with `transition/request`. If you also run the Sharetribe Web Template, set its listing type's process alias to `simple-request/release-2`. Confirm this step in Console during P7.

## Sandbox data

Create in Console: one provider user with at least one **published** listing, and one customer user (the Flutter app logs in as the customer). If the app shows no listings, this step is the usual cause, not the app.
