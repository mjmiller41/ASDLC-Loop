# 02 — Verify-gate keys off git state, not self-reported phase

**What to build:** The verify-gate (Stop hook) becomes a floor that fires on **observable git state**
instead of the director's self-reported `phase`. It runs when a build is **active** and the working
tree is **dirty**, regardless of what `phase` says; it stays dormant when not active, when active but
the tree is clean, and when `level` is `prototype`. Ordering and the diff-size guard are unchanged
(cheapest-first: lint → types → tests, then diff-size against the recorded base). `phase` remains in
state only to drive softer nudges — it no longer gates the floor. (ADR-0002)

**Blocked by:** 01.

**Status:** done

- [x] Gate blocks (exit 2) when active and the tree is dirty, for ANY `phase` value
- [x] Gate is dormant when not active
- [x] Gate is dormant when active but the working tree is clean
- [x] Gate is dormant when `level` is `prototype`
- [x] Commands still run cheapest-first and block on the first failure
- [x] Diff-size guard still blocks when the diff against the recorded base exceeds `diffSize`
- [x] Behavioural cases at the seam cover each of the above
