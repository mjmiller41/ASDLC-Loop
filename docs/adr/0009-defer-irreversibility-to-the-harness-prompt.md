# Irreversibility floor is the harness permission prompt; the Loop only reminds

Irreversible actions (prod deploy, data migration, live money) are the one place a directed step's
skip is unrecoverable. But those actions run through `Bash`, and the harness (Claude Code) already
prompts the human before executing a `Bash` call — the human is present at the moment of execution
regardless of what `build.md` says. That prompt *is* the hard floor for irreversibility.

So the Loop **does not duplicate a floor the harness already enforces.** Ship's "get explicit
authorization for anything irreversible" stays a **directed** reminder layered on top of the harness
prompt, with green CI as a directed precondition.

We reject a built-in "irreversible action detector" in the language-agnostic core: a generic detector
is project-specific and false-positive-prone, and over-blocking tempts people to disable the whole
gate (the failure ADR-0001 warns against). Instead, a project may *opt in* to `dangerCommands` —
regexes in `asdlc.config.json` that a `PreToolUse: Bash` hook flags for confirmation. Off by default,
because which commands are irreversible is inherently a per-project fact the core can't know.

Principle: **the Loop defers to harness-provided floors and only reminds where the harness already
guards.**
