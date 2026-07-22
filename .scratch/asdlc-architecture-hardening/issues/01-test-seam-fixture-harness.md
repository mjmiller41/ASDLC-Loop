# 01 — Test seam: fixture builder + run_case harness + baseline structural check

**What to build:** The shared test seam every later ticket lands on. A fixture builder that stands up
a throwaway git repo with a chosen `asdlc-state.json`, `asdlc.config.json`, and working-tree state
(clean/dirty, staged diff, base rev); a `run_case` harness that invokes a planted hook script as a
subprocess with a stdin payload and asserts its exit code (0 = allow, 2 = block) plus an stderr/stdout
substring; and a structural scaffold-output check that runs `scaffold.sh` into a temp dir and asserts
**today's** planted set of files and hook registrations. Green against the current templates — it
establishes the seam without changing behaviour.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] A reusable fixture builder creates a temp git repo and writes chosen state/config/working-tree
- [x] `run_case` runs a hook script as a subprocess with stdin and asserts exit code + message substring
- [x] Harness works with `bats` if available, else a minimal plain-bash runner; fixture builder is shared
- [x] Structural check runs `scaffold.sh` into a temp dir and asserts the current planted files exist
- [x] Structural check asserts the current `settings.json` hook registrations are present
- [x] The whole suite passes against the current templates (no behaviour changed)
- [x] A single command runs the suite (documented for CI reuse in later tickets)
