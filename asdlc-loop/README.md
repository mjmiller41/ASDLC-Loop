# asdlc-loop

Seed plugin for the **ASDLC Loop** (an Agentic SDLC for solo + Claude Code). Its only job is
**genesis**. It ships two commands and a set of templates; it ships **no hooks of its own**.

## The model: plugin is the seed, the repo is self-contained

- The **plugin** is the one machine-global thing — it must exist before any project does.
- `/asdlc-init` (or `/asdlc-adopt`) **plants governance into the target repo and commits it**:
  the gates, the `/build` orchestrator, the `/asdlc-off` escape hatch, the clean-context
  `code-reviewer` subagent, and `asdlc.config.json`.
- After genesis, the repo is **self-sufficient**: a teammate who clones it gets `/build` and the
  gates automatically, with or without this plugin installed.

## What gets planted (all committed into the project)

```
.claude/settings.json        dispatcher hook registrations (language-agnostic)
.claude/asdlc/*.sh            guard + gate dispatchers (on-stop, on-write, on-subagent)
.claude/asdlc.config.json     the "build level" + stack-specific gate commands
.claude/commands/build.md    the /build orchestrator — travels WITH the repo
.claude/commands/asdlc-off.md escape hatch to clear asdlc state
.claude/agents/code-reviewer.md   clean-context, spec-aware diff reviewer
.gitignore                   ignores .claude/asdlc-state.json (runtime only)
docs/specs/                  where approved specs live
CLAUDE.md                    seed with the ASDLC Loop house rules
.github/workflows/gates.yml  CI backstop — runs the same gates outside the agent
```

## Two files, two jobs

- **`asdlc.config.json`** — *static, committed.* Declares the project's **build level**
  (`prototype` | `standard` | `production`) and its **stack commands** (`test`/`lint`/`types`/`format`).
  The only stack-specific surface in the whole system.
- **`asdlc-state.json`** — *runtime, gitignored.* The sentinel: is a build active, which phase,
  which session. Every build-scoped hook reads it first and no-ops when no build is in progress —
  this is how the gates stay silent outside a `/build`.

## Isolation, in one line

Hooks fire globally by default; these gates **self-gate** on `asdlc-state.json` (present + active +
matching session) and on the current **phase**, so they enforce *only* during a `/build` and are
invisible the rest of the time.
