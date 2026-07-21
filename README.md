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
