---
name: new-adr
description: Record a new Architecture Decision Record for this repo. Use whenever a phase makes an architecture decision, the user asks to "write/add an ADR", or a change would contradict an Accepted ADR (then write a superseding one).
---

# New ADR

AGENTS.md requires an ADR for every new architecture decision. Follow every step; the ADR is not done until the index and links exist.

## Steps

1. **Pick the number.** List `docs/adr/` and read the `Planned:` line at the bottom of `.claude/second-brain/decisions.md`. Use the next number that is neither taken nor reserved there. When you write a *planned* ADR, use its reserved number and remove it from the `Planned:` line.
2. **Check for conflicts.** Read the Accepted ADRs the decision touches. If it contradicts one, the new ADR must say "Supersedes [NNNN]", and the old ADR's Status becomes `Superseded by [NNNN](NNNN-title.md)` (update its index row too).
3. **Write the file.** Copy `docs/adr/template.md` to `docs/adr/NNNN-kebab-title.md`. Fill every section: Status (`Accepted` if the user decided it, else `Proposed`), today's date, Phase, Context, Decision (one or two sentences), Alternatives rejected, Consequences. Use the terms in `.claude/second-brain/glossary.md`.
4. **Index it.** Add one row to the table in `.claude/second-brain/decisions.md`: `| [NNNN](../../docs/adr/NNNN-kebab-title.md) | <decision in a few words> | <Status> | <Phase> |`.
5. **Link it.** If a row in the "Working decisions" table of `docs/q-and-a.md` matches the decision, put the ADR link in its ADR column (and set Status to Decided when the ADR is Accepted). If no row matches, do not invent one; say so in your reply.
6. **Verify.** Every link resolves: `ls docs/adr/NNNN-*.md` and check the index row path. Then report the number, title, status and files changed.

Do not commit unless the user asked.
