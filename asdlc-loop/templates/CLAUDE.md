# Project house rules — governed by the ASDLC Loop (ASDLC-Loop)

This repo carries its own governance in `.claude/` (committed). It travels on clone; you do **not**
need the ASDLC-Loop plugin installed to work here.

## How work happens
- Run a unit of work with **`/build <task>`**. It routes by blast radius (Quick / Standard / Heavy),
  frames an approved spec, builds under TDD, reviews in a clean context, and ships.
- **`/asdlc-off`** disarms the build gates if one wedges.

## The floors (enforced by hooks, not by asking)
Two things always block, and `production` adds a third (the commit-floor, below). Everything else in
`/build` is **directed** — the loop instructs the agent to do it, and a determined agent (or you) can
step around it. That is deliberate: scaffold, not sandbox.
- **Secret-scan** (always on) — a write whose content carries an obvious credential is blocked
  outright. A credential must never land on disk.
- **Verify-gate** (during an active `/build`, above `prototype`) — lint → types → tests → diff-size
  must pass before a turn can finish. Tune commands in `.claude/asdlc.config.json`; an empty
  command skips that gate.

## Directed by the loop (not hard-enforced)
- **Format** — files are formatted after a write (a convenience, not a gate).
- **Reviewer** — the `code-reviewer` subagent reviews the diff against the spec in a clean context
  and writes a verdict artifact (`.claude/asdlc/verdicts/<base>-<head>.json`); the **`coder`**
  subagent that wrote the change may not approve its own work. This separation is directed.
- **Commit-floor** — before a `git commit` during an active build, a hook checks for a fresh
  `APPROVE` verdict matching the current `<base>-<head>`. Its strength follows `level` (see below):
  at `standard` a missing/stale verdict only nudges (directed); at `production` it **blocks** the
  commit (a floor). Advancing HEAD past the reviewed commit invalidates the verdict.
- **Phase sequence, approval gates, TDD-first** — sequenced by `/build`, held by the agent.
- **Irreversibility** — `/build` reminds the agent to get your explicit ok before anything
  irreversible (prod deploy, migration, live money), deferring the real stop to the harness'
  own permission prompt. For project-specific commands you want flagged, add extended-regexes to
  the optional `dangerCommands` array in `.claude/asdlc.config.json`.

## Two axes of rigor
- **`level`** (in `.claude/asdlc.config.json`, committed) **moves the floors**: `prototype`
  (secrets + format only — verify-gate skipped), `standard` (default — verify-gate + directed
  review), `production` (adds a mandatory, commit-blocking review and a human ship gate).
- **`track`** (per task, chosen at `/build` time) **moves only ceremony**: Quick / Standard / Heavy
  dial how much spec, planning, and review a single task carries — never the floors underneath.

## Ship clean
Exclude `.claude/` from published/deployed artifacts (`.npmignore` / build copy step). Governance
lives in the repo, never in the shipped bundle.
