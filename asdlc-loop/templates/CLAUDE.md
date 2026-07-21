# Project house rules — governed by the Director's Loop (ASDLC-Loop)

This repo carries its own governance in `.claude/` (committed). It travels on clone; you do **not**
need the ASDLC-Loop plugin installed to work here.

## How work happens
- Run a unit of work with **`/build <task>`**. It routes by blast radius (Quick / Standard / Heavy),
  frames an approved spec, builds under TDD, reviews in a clean context, and ships.
- **`/loop-off`** disarms the build gates if one wedges.

## The gates (enforced by hooks, not by asking)
- **Secret-scan** (always on) — writes containing an obvious credential are blocked.
- **Format** (always on) — files are formatted on write.
- **Verify-gate** (only during a `/build`, phases build/review) — lint → types → tests → diff-size
  must pass before a turn can finish. Tune commands in `.claude/loop.config.json`.
- **Reviewer** — the `code-reviewer` subagent reviews the diff against the spec; the author agent
  may not approve its own work.

## Rigor level
Set in `.claude/loop.config.json` → `level`: `prototype` (secrets+format only), `standard` (default),
or `production` (stricter). The per-task track can dial ceremony down within the level, never the
safety below it.

## Ship clean
Exclude `.claude/` from published/deployed artifacts (`.npmignore` / build copy step). Governance
lives in the repo, never in the shipped bundle.
