# The ASDLC Loop is a scaffold, not a sandbox

The Loop governs a **solo operator working with Claude Code**, so the threat model is *the operator
moving fast and skipping their own discipline* — not a malicious actor defeating controls. We
therefore design the system as a **scaffold**: it makes the disciplined path the path of least
resistance and makes every deviation loud and visible, resting on a small number of genuinely
deterministic **hard floors** (secrets never reach disk; a turn cannot silently finish red).

Everything else — the `/build` phase sequence, approval gates, TDD-first, separation of duties — is
a **directed step**: instructed, made-visible, but bypassable. This is deliberate. `asdlc.config.json`
is editable, CI (`gates.yml`) is advisory (the solo Git workflow skips branch protection), and the
director is an LLM that can drift. We accept all of that rather than pretend the system is a hard
guarantee.

Consequence: documentation must scope the phrase "enforced by hooks, not by asking" to the two or
three actual hard floors, and label the rest honestly as directed. A future contributor who reads
"enforced" and assumes un-bypassable guarantees would misunderstand the design.
