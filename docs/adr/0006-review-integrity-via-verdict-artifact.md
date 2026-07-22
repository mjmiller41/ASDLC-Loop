# Review integrity: directed dispatch, visible verdict artifact, production-level floor

Separation of duties can't be hard-enforced for quality — an LLM reviewer can rubber-stamp, and the
reviewer is dispatched by the director it's meant to check. So we harden what is honestly
enforceable — that review *was recorded* — not what isn't (that review was *good*).

The reviewer writes a **verdict artifact** keyed to the diff it reviewed (`base..head` SHAs): verdict
plus findings. Because it is keyed to the SHA range, it goes stale automatically when more code lands
— you cannot review once and keep shipping. **Ship** reads it:

- at **`standard`**, a missing or stale review is a loud nudge;
- at **`production`**, "a current APPROVE artifact matching `base..HEAD` exists" is a **floor** — a
  `PreToolUse` git-commit check (mirrored in `gates.yml`) blocks the commit/PR without it.

Consistent with ADR-0004: `level` moves the floor. The director could still fabricate the artifact,
but writing a file with a matching SHA is a deliberate, visible act, not a silent omission, and it
gives CI a concrete artifact to check. Rejected: no artifact (skipping review stays invisible); an
artifact floor at `standard` too (too heavy for everyday work — kept as a nudge there).
