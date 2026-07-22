# ASDLC-Loop (marketplace)

Local marketplace hosting a single plugin: **`asdlc-loop`** (in [`./asdlc-loop`](./asdlc-loop)).

The plugin is the *seed* for the **ASDLC Loop** — a solo-operator, tiered, gated development
lifecycle for running real projects through Claude Code. It plants **committed, self-contained
governance** into a repo (gates, a `/build` orchestrator, a clean-context reviewer) so the
enforcement travels on `git clone` and never depends on the plugin being installed to *work in*
a project. You only need the plugin to *create or adopt* projects.

## Install (local, during development)

```bash
# register this directory as a marketplace, then enable the plugin
claude plugin marketplace add ~/Code/claude-plugins/ASDLC-Loop
claude plugin enable asdlc-loop@asdlc-loop-marketplace
```

Then run `/reload-plugins` in your session so the new commands load.

## What you get

| Command | Purpose |
|---|---|
| `/asdlc-init` | Scaffold a **new** project: git init, stack-aware toolchain, and the committed `.claude/` governance, all in commit 1. |
| `/asdlc-adopt` | Retrofit an **existing** repo, idempotently — adds only what's missing. |

Everything the commands plant (hooks, `/build`, `/asdlc-off`, the reviewer subagent, `asdlc.config.json`)
lives in the target project and is committed there. See [`asdlc-loop/README.md`](./asdlc-loop/README.md).

## Walkthrough: from empty directory to a shipped feature

A complete first run — creating a new TypeScript project, building one feature through the loop, and
seeing the gates fire. Everything below happens inside a Claude Code session; lines you type start
with `>`, and the surrounding blocks show a representative (illustrative) response.

### 0. Install the plugin — once per machine

```bash
claude plugin marketplace add ~/Code/claude-plugins/ASDLC-Loop
claude plugin enable asdlc-loop@asdlc-loop-marketplace
```

Then `/reload-plugins` in your session. You need the plugin only to *create or adopt* a project —
never to work inside one afterward.

### 1. Create the project — `/asdlc-init`

```
> /asdlc-init ~/Code/todo-api
```

Claude confirms the target directory, infers (or asks) the stack and rigor **level**, then plants the
committed governance in a single baseline commit:

```
Stack: Node/TypeScript   Level: standard
$ bash scaffold.sh ~/Code/todo-api standard
OK: universal core scaffolded into ~/Code/todo-api (level=standard)
$ git commit -m "chore: scaffold ASDLC Loop (Node/TS, level=standard)"
```

Your repo now carries its own enforcement, all committed under `.claude/`:

```
.claude/settings.json          hook registrations (language-agnostic)
.claude/asdlc/*.sh             the gate dispatchers (secret-scan, verify-gate, commit-floor, …)
.claude/asdlc.config.json      level + your stack's gate commands
.claude/commands/build.md      the /build orchestrator — travels with the repo
.claude/agents/coder.md        implements one scoped task in a clean context
.claude/agents/code-reviewer.md  reviews the diff against the spec, never its own work
.github/workflows/gates.yml    CI backstop — the same gates outside the agent
CLAUDE.md                      the house rules
```

`asdlc.config.json` is the only stack-specific surface — the `level` and the commands each gate runs:

```json
{
  "level": "standard",
  "commands": {
    "test":  "npx vitest run",
    "lint":  "npx eslint .",
    "types": "npx tsc --noEmit",
    "format": "npx prettier -w"
  },
  "gates": { "diffSize": 400, "review": true }
}
```

### 2. Build a unit of work — `/build`

From here on you don't need the plugin — `/build` lives in the repo. Kick off a task:

```
> /build add a POST /todos endpoint that validates the body and persists a todo
```

Typing `/build` **arms the loop**: a hook writes `.claude/asdlc-state.json` (`active`, `phase`,
`base` = current HEAD). That sentinel is gitignored and is what wakes the otherwise-silent gates.
The loop then runs its phases:

**Route** — Claude classifies the task by blast radius and picks a **track**:

```
Track: Standard — a normal feature. Running the full loop.
```

**Frame** — it drafts a short spec to `docs/specs/<date>-add-todos-endpoint.md` (problem, scope,
acceptance criteria) and **stops for your approval before writing any code**:

```
Spec ready. Acceptance: 201 + created todo on valid body; 400 on missing title.
Approve to start building? (y / edits)
> y
```

**Design & Plan** — 2–3 approaches with trade-offs (you pick), then a task list with a test strategy.

**Build (verify-gate now live)** — it works test-first. The **verify-gate** runs on every turn-end:
`lint → types → tests → diff-size`, stopping at the first failure. A red test blocks the turn until
it's green:

```
● verify-gate: tests FAILED
  todos.test.ts › returns 201 on valid body — expected 201, received 404
  → turn blocked; fixing before continuing.
```

Claude implements the route, the gate goes green, and the turn completes. Two things always block no
matter what — the **secret-scan** (a write carrying a credential is rejected outright) and, above
`prototype`, this verify-gate. Everything else is *directed*: the loop instructs, and you or the agent
can step around it. Scaffold, not sandbox.

**Review (clean context)** — a separate `code-reviewer` subagent reviews the diff against the spec —
**the coder can't approve its own work** — and records a verdict artifact:

```
$ cat .claude/asdlc/verdicts/<base>-<head>.json
{ "verdict": "APPROVE", "findings": [] }
```

When you commit, the **commit-floor** checks for a fresh `APPROVE` matching the current change range.
At `standard` a missing/stale verdict is a nudge; at `production` it **blocks the commit**. (Advancing
HEAD past the reviewed commit invalidates the verdict — you can't review once and keep shipping.)

**Ship** — commit, open a PR, deploy where reversible. For anything irreversible (prod deploy,
migration, live money) the loop pauses for your explicit ok and defers the real stop to Claude Code's
own permission prompt. Then it disarms the gates.

### 3. Two axes of rigor

- **`level`** (committed in `asdlc.config.json`) **moves the hard floors**: `prototype` (secrets +
  format only), `standard` (default), `production` (adds a commit-blocking review + a human ship gate).
- **`track`** (chosen per `/build`) **moves only ceremony**: `Quick` skips the spec/plan for a
  one-liner; `Heavy` adds worktree isolation and adversarial multi-vote review. It never lowers the
  floors underneath.

### 4. If a gate wedges — `/asdlc-off`

Stuck behind a gate mid-task? Clear the build state and the gates go dormant again:

```
> /asdlc-off
```

### 5. What a teammate gets — nothing to install

Because the governance is committed, a collaborator who clones the repo gets `/build`, the gates, and
the reviewer automatically — **with or without this plugin installed**. The plugin was only ever the
seed; the repo is self-sufficient from commit 1.

> Retrofitting an existing repo instead of starting fresh? Use `/asdlc-adopt` — it's idempotent, adds
> only what's missing, merges (never clobbers) an existing `.claude/settings.json`, and standardizes
> the trunk on `main`.
