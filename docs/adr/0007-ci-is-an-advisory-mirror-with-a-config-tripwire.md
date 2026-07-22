# CI is an advisory external mirror with a config-integrity tripwire

Per ADR-0001 no floor is un-bypassable for a solo operator, and the solo Git workflow keeps no branch
protection — so CI cannot be an authority. We define its role positively instead:

- **Honest external mirror.** `gates.yml` re-runs the floors *outside the agent's context*, producing
  a second, agent-independent observation in the commit/PR status. Its value is being a witness the
  agent cannot ghost-write — not merge-blocking power. It is explicitly **advisory**: a red check must
  be *chosen* to be respected.
- **Config-integrity tripwire.** Because `asdlc.config.json` is committed-but-editable and CI runs its
  commands, gutting the config (blanking commands, dropping to `prototype`) would silently pass. So CI
  adds a check on the config itself: at `standard`, lint/types/test commands must be non-empty; at
  `production`, the review floor must be on. Weakening the governance now turns CI **red**.

Why the tripwire matters specifically here: the operator is **solo**, so no human ever reviews the
`asdlc.config.json` diff. CI is the only reviewer a config-weakening commit will ever face; the
tripwire turns a quiet config edit into a visible red check. Deliberately ignoring red, or weakening
the tripwire itself, stays possible and visible — which is the scaffold stance, not a failure of it.
Rejected: authoritative CI (introduce branch protection) — breaks the solo "skip branch protection"
rule; plain mirror with no config check — leaves the one silent-weakening path silent.
