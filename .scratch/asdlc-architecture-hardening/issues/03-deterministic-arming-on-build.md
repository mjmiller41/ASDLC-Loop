# 03 — Deterministic arming on /build invocation

**What to build:** Arming a build stops depending on the director. A new `UserPromptSubmit` hook
recognises a real `/build` invocation and writes `active=true` and `base=<current HEAD>` into the
runtime state itself, before the director acts — so a build the human asked for can never be silently
un-armed. A prompt that merely mentions the word "build" in prose must NOT arm. The hook is registered
in the planted `settings.json`, and the structural check is extended to assert that registration.
(ADR-0003)

**Blocked by:** 01.

**Status:** ready-for-agent

- [ ] A `/build ...` prompt arms the build: `active=true` and `base` set to current HEAD
- [ ] A prompt that only mentions "build" in prose does not arm
- [ ] Planted `settings.json` registers the `UserPromptSubmit` hook
- [ ] Structural check asserts the new registration
- [ ] Behavioural cases at the seam cover arm-vs-no-arm
- [ ] Opting out (never running `/build`, or `/asdlc-off`) remains possible and unaffected
