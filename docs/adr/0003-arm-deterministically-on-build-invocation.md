# Arming is deterministic on `/build` invocation, not a directed step

If the director (an LLM) is responsible for writing `active=true`, a human who invokes `/build` can
end up with an *un-armed* build: the loop appears to run, code is written, and no floor fires — a
silent deviation, the exact failure the scaffold stance forbids.

We therefore arm from a **`UserPromptSubmit` hook** that recognizes a `/build` invocation and writes
`active=true` (and `base=HEAD`) before the director acts. Arming moves from directed to a **hard
floor**: the director can no longer fail to arm a build the human asked for. The director still fills
softer fields (`track`, `phase`) used only for nudges.

Opting *out* stays a visible human act — never running `/build`, or running `/asdlc-off`. Only the
*arming after opt-in* is made deterministic. Considered and rejected: (a) leave arming directed —
keeps the silent-skip gap; (c) drop `active` and infer from branch + dirty tree — un-fakeable but
fires the gate on exploratory scratch branches the operator never meant to govern.
