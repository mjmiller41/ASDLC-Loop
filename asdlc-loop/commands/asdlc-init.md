---
name: asdlc-init
description: Scaffold a NEW project with the ASDLC Loop — git init, stack-aware toolchain, and committed governance (gates, /build, reviewer) in commit 1.
---

Scaffold a new ASDLC Loop project. The governance is **committed**, so it travels on clone and
never depends on this plugin afterward.

**Target:** `$ARGUMENTS` if given (a path or new dir name), else the current directory. Confirm with
the user which directory before writing.

## Steps

1. **Determine the stack.** Infer it from what the user is building; if unclear, ask ONE question:
   Node/TypeScript · Python · Go · Other · None (docs/scripts). Pick the level too — default
   `standard` unless the user says it's a throwaway (`prototype`) or a service (`production`).

2. **Plant the universal core** (deterministic — do not hand-roll this):
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh" "<target-dir>" "<level>"
   ```

3. **Fill the stack gate commands** in `.claude/asdlc.config.json` (empty command = gate skipped).
   Presets:
   | Stack | test | lint | types | format |
   |---|---|---|---|---|
   | Node/TS | `npx vitest run` | `npx eslint .` | `npx tsc --noEmit` | `npx prettier -w` |
   | Python | `uv run pytest \|\| [ $? -eq 5 ]` | `uv run ruff check` | `uv run mypy .` | `uv run ruff format` |
   | Go | `go test ./...` | `go vet ./...` | — | `gofmt -w` |
   | None | — | — | — | `prettier -w` (or leave empty) |

   **Gate commands must resolve in the project's toolchain env**, so prefix them: Python → `uv run`
   (you run `uv init` in step 4); Node → `npx` (tools live in `node_modules/.bin`); Go tools are on PATH.
   The `|| [ $? -eq 5 ]` on pytest lets an **empty baseline pass** (pytest exits 5 on "no tests
   collected") while a real failure (exit 1) still blocks the gate.

   Write them with jq, e.g.:
   ```bash
   jq '.commands={test:"npx vitest run",lint:"npx eslint .",types:"npx tsc --noEmit",format:"npx prettier -w"}' \
     .claude/asdlc.config.json > c && mv c .claude/asdlc.config.json
   ```

4. **Run the stack toolchain — ONLY if the stack needs it.** Node → `npm init -y` + install the dev
   deps you referenced. Python → `uv init`. Go → `go mod init`. **None → do nothing** (do not create
   `node_modules` or a package manifest for a project that won't use one).

5. **Adjust `.github/workflows/gates.yml`** setup block for the stack if it isn't Node.

6. **Commit the baseline:**
   ```bash
   git add -A && git commit -m "chore: scaffold ASDLC Loop (<stack>, level=<level>)"
   ```

7. **Hand off.** Tell the user: enforcement is live and committed; start work with `/build <task>`.
   Note that gates only arm inside a `/build` (except secret-scan + format, which are always on).
