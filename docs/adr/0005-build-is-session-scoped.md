# A build is session-scoped; multi-session work lives at the ticket grain

The `SessionStart` hook disarms any leftover build state, so every session begins with the
build-scoped floors dormant. This looks like it "loses" an interrupted build, but it is deliberate:
**a build is session-scoped.** One `/build` is one unit of work meant to fit inside a single context
window (the smart zone); a build not finished in its session is treated as abandoned, not resumed.

Multi-session work is modeled one level up: an **effort** is decomposed into tickets, and each ticket
is its own fresh `/build` in a clean context. We never resume a build — we start the next ticket's.

This keeps the state model minimal: one global sentinel, no session ids, no staleness judgment, no
resume state machine, and the "a crashed build never leaves the gates hot" guarantee comes for free.
Rejected: resumable builds (track session/branch, offer re-arm on SessionStart) — more robust to
interruption but reintroduces the gates-left-hot risk and a "is this stale?" judgment. The accepted
cost: a dropped build is re-entered as a fresh `/build`, not continued from its phase.
