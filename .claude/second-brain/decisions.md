# Decisions (index)

Index only. The ADRs themselves live in `docs/adr/`. Add one line here per ADR, and keep the Status column in sync.

| ADR | Decision | Status | Phase |
|--|--|--|--|
| [0001](../../docs/adr/0001-flutter-bloc-cubits.md) | flutter_bloc Cubits, not Provider/Riverpod | Accepted | P0 |
| [0002](../../docs/adr/0002-dio-queued-interceptor.md) | dio + QueuedInterceptor: single-flight refresh on 401 | Accepted | P0 |
| [0003](../../docs/adr/0003-process-versioning-release-2-alias.md) | New `release-2` alias; `release-1` never moves | Accepted | P0 |
| [0004](../../docs/adr/0004-mock-default-live-first-readme.md) | Mock default for dev/tests; README leads with live | Accepted | P0 |
| [0005](../../docs/adr/0005-request-flow-as-stretch.md) | In-app request flow is stretch (P4b) | Accepted | P0 |
| [0006](../../docs/adr/0006-agents-md-single-source.md) | AGENTS.md single source; CLAUDE.md = `@AGENTS.md` | Accepted | P0 |
| [0007](../../docs/adr/0007-v2-provider-accept.md) | v2 adds provider accept/decline + 3-day expiry | Accepted | P1 |
| [0008](../../docs/adr/0008-hand-written-no-payment-baseline.md) | Hand-written minimal no-payment v1 baseline | Accepted | P1 |
| [0011](../../docs/adr/0011-models-before-code.md) | Process and domain models come before code (MDD) | Accepted | P1–P2 |
| [0012](../../docs/adr/0012-agent-harness-hooks-and-skills.md) | Guard hook + `new-adr` skill now; verify hooks at end of P2a | Accepted | P0, P2a |

Planned: 0009 Result/AppError over exceptions (P2a) · 0010 token storage (P2a)
