# 07 — Optional dangerCommands hook

**What to build:** An opt-in guard for project-specific irreversible commands. `asdlc.config.json`
gains an optional `dangerCommands` array of regexes. A new `PreToolUse: Bash` hook flags a command
that matches any of them for explicit confirmation, and no-ops entirely when the list is absent or
empty. This is the per-project substitute for a generalised irreversible-action detector, which the
core deliberately does not ship — which commands are irreversible is a per-project fact. Registration
added and structural check extended. (ADR-0009)

**Blocked by:** 01.

**Status:** ready-for-agent

- [ ] `asdlc.config.json` supports an optional `dangerCommands` array
- [ ] The hook flags a Bash command that matches a configured regex
- [ ] The hook no-ops when `dangerCommands` is absent or empty
- [ ] Planted `settings.json` registers the `PreToolUse: Bash` hook; structural check asserts it
- [ ] Behavioural cases at the seam cover match / no-match / unconfigured
