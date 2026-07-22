# The verify-gate keys off observable git state, not self-reported phase

The verify-gate is our one deterministic code-quality **hard floor**, but its trigger conditions
must not be trivially fakeable by the same LLM director it checks. `phase` is a free-text field the
director writes into `asdlc-state.json`; keying the floor on `phase ∈ {build, review}` means the
floor evaporates whenever the director sets a different phase or skips the transition.

We therefore trigger the verify-gate on **observable repo reality**: a build is *active* **and** the
working tree has an uncommitted diff. A dirty tree is the honest signal that "code now exists and a
turn is ending," and the director cannot fake it without actually committing. `phase` is retained
only for softer, phase-specific *nudges* (e.g. the reviewer reminder), never as a precondition for
the floor itself.

Trade-off accepted: the gate may now run during turns the director considers "planning" if code was
in fact written — which is the point. `active` remains director-controlled for now; whether *that*
toggle should also be inferred is a separate open question.
