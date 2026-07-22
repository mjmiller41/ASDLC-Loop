# 04 — Committed coder subagent + "every named role is a committed file" rule

**What to build:** Plant a committed `coder` subagent so the Loop is self-sufficient after genesis.
`build.md` names a coder to dispatch, but none is planted today — a cloned repo references a role that
isn't there. Add a `coder.md` primed with TDD-first (RED before GREEN), scope-restraint (implement
only the task), and diff-budget awareness — isolated for context hygiene, dispatched as ceremony (not
a floor). Extend the structural check to enforce the rule: every role `build.md` names must exist as a
committed file. (ADR-0008)

**Blocked by:** 01.

**Status:** ready-for-agent

- [ ] A `coder.md` subagent is planted, carrying TDD-first, scope-restraint, and diff-budget discipline
- [ ] `scaffold.sh` plants the coder alongside the reviewer
- [ ] Structural check asserts every role `build.md` names has a committed file (incl. coder)
- [ ] The coder is documented as context-hygiene ceremony, distinct from the reviewer's independence role
