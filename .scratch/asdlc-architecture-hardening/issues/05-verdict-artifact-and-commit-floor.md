# 05 — Verdict artifact + commit-floor

**What to build:** Make review's presence visible and, at `production`, a floor. The reviewer writes a
**verdict artifact** — a committed record of the verdict (APPROVE / REQUEST CHANGES), findings, and
the `base..head` SHA range it reviewed. A new commit-path hook reads it: at `level: production` it
blocks a commit unless a verdict artifact whose `base..head` matches the diff being committed says
APPROVE; at `standard` it emits a nudge instead of blocking. Freshness is by SHA-range match, not
timestamp, so the artifact goes stale automatically when more code lands. The hook is registered and
the structural check extended. (ADR-0006)

**Blocked by:** 01.

**Status:** ready-for-agent

- [ ] The reviewer subagent writes a verdict artifact keyed to the reviewed `base..head` SHAs
- [ ] At `production`, commit is blocked when no matching artifact exists
- [ ] At `production`, commit is blocked when the matching artifact says REQUEST CHANGES
- [ ] At `production`, commit is blocked when the artifact's range is stale (more code landed)
- [ ] At `production`, commit is allowed on a current matching APPROVE
- [ ] At `standard`, the same conditions nudge but never block
- [ ] Planted `settings.json` registers the commit-path hook; structural check asserts it
- [ ] Behavioural cases at the seam cover each production/standard condition
