# 08 — Prose rescope: honest floors, precise axes

**What to build:** Bring the planted prose in line with the shipped behaviour so it stops overselling.
Rescope `build.md` and `CLAUDE.md` so "enforced by hooks, not by asking" names only the true floors
(secret-scan; verify-gate); state the two-axis rule precisely — `level` moves the floors, `track`
moves only ceremony; describe the verdict artifact and commit-floor and the `coder` role; and keep the
irreversibility guidance as a directed reminder that defers to the harness permission prompt. This is
last so the docs describe behaviour that actually exists. These are directed artifacts with no
behavioural contract — the structural check only asserts they are planted. (ADR-0001, ADR-0004)

**Blocked by:** 02, 03, 04, 05, 06, 07.

**Status:** done

- [x] `build.md` and `CLAUDE.md` scope "enforced" to secret-scan + verify-gate only; everything else is labelled directed
- [x] The `level`-moves-floors / `track`-moves-ceremony distinction is stated precisely
- [x] The verdict artifact + commit-floor behaviour is described
- [x] The `coder` role is referenced alongside the reviewer
- [x] Irreversibility is described as a directed reminder deferring to the harness prompt (+ optional `dangerCommands`)
- [x] Prose matches the behaviour shipped by tickets 02–07 (no aspirational claims)
