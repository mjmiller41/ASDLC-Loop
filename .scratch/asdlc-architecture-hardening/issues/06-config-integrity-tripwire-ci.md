# 06 — Config-integrity tripwire in CI

**What to build:** The external mirror (`gates.yml`) gains a config-integrity step that guards the
editable-config hole. Because CI runs the config's own commands, gutting the config (blanking
commands, dropping to `prototype`) would silently pass — so add a check on the config itself: at
`standard`, `commands.lint/types/test` must be non-empty; at `production`, the review floor
(`gates.review`) must be on. Failing the check fails CI, turning a quiet config-weakening commit into a
visible red — the only "reviewer" such a commit ever sees on a solo repo. Implement the check as a
small script so it is testable at the behavioural seam. CI stays advisory (no branch protection).
(ADR-0007)

**Blocked by:** 01.

**Status:** done

- [x] A config-integrity check script passes on a well-formed `standard` config
- [x] It fails when `standard` and any of lint/types/test commands is empty
- [x] It fails when `production` and the review floor is off
- [x] It passes for `prototype` (no command requirement)
- [x] `gates.yml` runs the check as an advisory step (no branch protection introduced)
- [x] Behavioural cases at the seam cover pass/fail per level
