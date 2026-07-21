---
name: asdlc-adopt
description: Retrofit an EXISTING repo with the Director's Loop, idempotently — adds only what's missing and merges (never clobbers) existing Claude Code settings.
---

Adopt the Director's Loop into the existing repo at the current directory (or `$ARGUMENTS`). This is
safe to run more than once; it only adds what's missing.

## Steps

1. **Detect the stack from the repo**, don't ask if you can tell: `package.json` → Node (read its
   `scripts` for real lint/test/format commands); `pyproject.toml`/`setup.py` → Python;
   `go.mod` → Go. Use the project's actual commands, not generic defaults.

2. **Plant the universal core** (idempotent; preserves existing config + settings):
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh" "$(pwd)" standard
   ```

3. **Handle `MERGE_NEEDED`.** If the script reports an existing `.claude/settings.json`, **merge**
   the Director's Loop hooks into it — do not overwrite. Deep-merge each event; for an event that
   already has entries, append our dispatcher hook alongside the existing ones. Show the user the
   merged result before saving.

4. **Fill `.claude/loop.config.json` commands** from the project's real toolchain (step 1). Pick the
   `level` with the user: `standard` for an active project, `production` for anything that ships to
   users.

5. **Wire CI** only if the repo has no equivalent gate workflow already; otherwise leave theirs and
   note the overlap.

6. **Commit:** `git add -A && git commit -m "chore: adopt Director's Loop"` — and tell the user the
   gates are now live and committed, startable with `/build`.

## Idempotency contract
Re-running refreshes the loop scripts/commands/agent, never touches an existing
`loop.config.json`, `CLAUDE.md`, or their `settings.json` hooks. If nothing is missing, it's a no-op
plus a scripts refresh.
