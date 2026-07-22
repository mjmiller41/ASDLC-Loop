---
name: build
description: Run a unit of work through the ASDLC Loop — route by blast radius, frame an approved spec, build under the verify-gate, review in a clean context, and ship. Arms the build-scoped gates for the duration.
---

You are the **director** of this build. Execute the ASDLC Loop for the task below.
Encode the sequence — don't just describe it. Update `asdlc-state.json` as you move so the
gates know which phase they're in.

**Task:** $ARGUMENTS

## Phase 0 — Route (pick the track by blast radius)
Classify the task and state your choice + one-line rationale:
- **Quick** — typo/config/copy/one-liner. Skip to Build; no spec, no plan.
- **Standard** (default) — a feature or bugfix. Full loop below.
- **Heavy** — large / risky / irreversible / cross-cutting. Full loop, plus decompose into
  isolated units (git worktrees) and use multi-vote review.

## Arm the loop
Record state so the verify-gate activates. Run this (adjust `phase` per track — Quick starts at `build`):
```bash
BASE="$(git rev-parse HEAD 2>/dev/null || echo '')"
jq -n --arg track "TRACK" --arg phase "frame" --arg base "$BASE" \
  '{active:true, track:$track, phase:$phase, base:$base}' \
  > .claude/asdlc-state.json
```

## Phase 1 — Frame  (skip on Quick)
Draft a short spec to `docs/specs/<date>-<slug>.md`: problem, scope, acceptance criteria, open
questions. **Gate: present it and get the user's approval before coding.** Then advance:
`jq '.phase="plan"' .claude/asdlc-state.json | sponge` (or write via a temp file).

## Phase 2–3 — Design & Plan  (skip on Quick)
Propose 2–3 approaches with trade-offs; the user picks. Then write a checkable task list with a
test strategy per task. **Gate: user approves the plan.** Advance phase to `build`.

## Phase 4 — Build  (verify-gate is now live)
Set `phase="build"`. Implement under TDD: for each task write the **failing test first (RED)**,
make it pass (GREEN), refactor. On Standard/Heavy, dispatch the **`coder` subagent**
(`.claude/agents/coder.md`) per task so implementation happens in a clean context. The Stop hook runs lint → types → tests → diff-size on
every turn; if it blocks, fix and continue. Keep changes under the diff-size budget.

## Phase 5 — Review  (directed separation of duties)
Set `phase="review"`. Dispatch the **`code-reviewer` subagent** (`.claude/agents/code-reviewer.md`)
in a clean context to review the diff against the spec. The reviewer writes a verdict artifact to
`.claude/asdlc/verdicts/<base>-<head>.json`. **The `coder` that wrote the change may not approve its
own work** — a directed rule, not a hard floor. On Heavy, run the reviewer 2–3 times (adversarial).
Address every finding, then get the user's ok. When you `git commit`, a hook looks for a fresh
`APPROVE` verdict matching the current `<base>-<head>`: at `production` a missing/stale one blocks the
commit, at `standard` it only nudges (advancing HEAD past the reviewed commit invalidates it).

## Phase 6 — Ship
Commit, open a PR, and deploy where reversible. **Directed reminder: get the user's explicit
authorization before anything irreversible** (prod deploy, data migration, live money) — the real
stop is the harness' own permission prompt; this loop only reminds you to pause. Project-specific
commands can be flagged for confirmation via the optional `dangerCommands` array in
`.claude/asdlc.config.json`. Ship a clean artifact — exclude
`.claude/` from the published/deployed bundle (that's what `.npmignore` / the build's copy step is for);
governance stays in the repo, never in the shipped package.

## Disarm
When the work is merged or paused, disarm the gates:
```bash
jq '.active=false' .claude/asdlc-state.json > .claude/asdlc-state.tmp && mv .claude/asdlc-state.tmp .claude/asdlc-state.json
```

## Phase 7 — Learn
If a bug surfaced, write the **regression test first**, then fix. Capture any durable lesson into
`CLAUDE.md` or a skill so the next loop starts smarter.
