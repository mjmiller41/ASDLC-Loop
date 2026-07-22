# Spec: ASDLC Loop architecture hardening

Status: ready-for-agent
Base: docs/adr/0001–0009, CONTEXT.md (this repo)

## Problem Statement

The `asdlc-loop` plugin plants governance into a repo and leans on the phrase *"enforced by hooks,
not by asking."* But when you trace the mechanism, most of the Loop is **directed** — LLM
instructions the director can silently drift from — while only a thin slice is a true **hard floor**.
Worse, several of the "floors" are conditional on state the director itself writes, so they can
evaporate without any signal. As the operator, I can't tell which parts of the system actually hold
and which are polite suggestions, and a cloned repo can silently run a `/build` with the gates never
armed, no review recorded, or the config quietly gutted — with nothing turning red.

I want the architecture to be *honest*: a small set of floors that hold even against the director's
own drift, everything else clearly labelled as directed-and-made-visible, and the one silent-weakening
path (gutting the committed config on a solo repo nobody reviews) turned loud.

## Solution

Reshape what the plugin plants so the **scaffold, not sandbox** stance (ADR-0001) is realised
precisely:

- The **verify-gate** floor keys off **observable git state** (a build is active and the working tree
  is dirty), not the director's self-reported `phase` (ADR-0002).
- **Arming** a build becomes deterministic: a `UserPromptSubmit` hook recognises a `/build`
  invocation and arms the state itself, so a build the human asked for can never be silently un-armed
  (ADR-0003).
- **Two rigor axes are separated**: `level` (committed, repo-wide) is the only dial that moves a
  floor; `track` (per-task) moves only ceremony and never reads a floor (ADR-0004).
- **Review** stays a directed dispatch but leaves a **verdict artifact** keyed to the reviewed diff's
  `base..head` SHAs; at `production` a current APPROVE is a floor at commit time, at `standard` its
  absence is a nudge (ADR-0006).
- **CI** (`gates.yml`) is an explicitly advisory **external mirror** plus a **config-integrity
  tripwire** that turns config-weakening red (ADR-0007).
- Every role `/build` names is a **committed file** — plant a `coder.md` (ADR-0008).
- **Irreversibility** defers to the harness permission prompt; the Loop only reminds, with an
  optional per-project `dangerCommands` hook (ADR-0009).
- The prose (`build.md`, `CLAUDE.md`) is rescoped so "enforced" names only the true floors and the
  `level`/`track` distinction is stated precisely.

All of this is exercised by one behavioural seam (each planted hook script run as a subprocess) and
one structural seam (the scaffold output), so the governance's guarantees are themselves tested.

## User Stories

1. As a solo operator, I want the system to describe itself honestly as a scaffold with a few hard
   floors, so that I know which guarantees hold and which are reminders.
2. As a solo operator, I want the verify-gate to fire whenever a build is active and I've actually
   changed files, so that a director that mislabels its `phase` can't skip the gate.
3. As a solo operator, I want the verify-gate to stay dormant when a build is active but nothing has
   changed, so that pure conversation turns aren't taxed.
4. As a solo operator, I want the verify-gate to run cheapest-first (lint → types → tests → diff-size)
   and block the turn on the first failure, so that I get the fastest possible red.
5. As a solo operator, I want typing `/build` to arm the build deterministically, so that the gates
   are live even if the director forgets to write the state file.
6. As a solo operator, I want prompts that merely *mention* build (not an actual `/build` invocation)
   to not arm a build, so that arming isn't triggered by accident.
7. As a solo operator, I want arming to record the base revision at invocation time, so that
   diff-size and the verdict artifact measure against the right starting point.
8. As a solo operator, I want every new session to start with the build-scoped floors disarmed, so
   that a crashed or abandoned build never leaves the gates hot.
9. As a solo operator, I want a single `/build` to be one session-scoped unit of work, so that the
   state model stays simple and multi-session work is decomposed into tickets instead.
10. As a solo operator, I want `/asdlc-off` to disarm on demand, so that a wedged build can be
    escaped without disabling the always-on floors.
11. As a solo operator, I want the secret-scan to run on every write regardless of build state, so
    that a credential can never land on disk.
12. As a solo operator, I want files formatted on write as a best-effort tidy that never blocks, so
    that formatting is not a gate.
13. As a solo operator, I want `level` to be the only dial that moves a floor, so that lowering
    safety is always a visible, committed edit.
14. As a solo operator, I want `prototype` level to skip the verify-gate entirely, so that spikes and
    throwaways carry only secrets + format.
15. As a solo operator, I want `production` level to add a mandatory review floor and tighter
    diff-size, so that high-stakes repos are held to a stricter bar.
16. As a solo operator, I want `track` to only change how much Frame/Plan/Review ceremony happens, so
    that a Quick one-liner skips paperwork but still pays the verify-gate.
17. As a solo operator, I want a Quick change to still be caught if it breaks lint/types/tests, so
    that careless small edits don't slip through.
18. As a solo operator working a large effort, I want to decompose it into tickets each worked as its
    own fresh `/build`, so that no single build outgrows one context window.
19. As a reviewing operator, I want the reviewer dispatched as a clean-context subagent, so that the
    agent which wrote the code never approves it.
20. As a reviewing operator, I want the reviewer to write a verdict artifact keyed to the reviewed
    diff's `base..head` SHAs, so that the review's presence and scope are visible on disk.
21. As a reviewing operator, I want the verdict artifact to go stale automatically when more code
    lands, so that I can't review once and keep shipping.
22. As an operator at `production` level, I want a commit to be blocked unless a current APPROVE
    artifact matches the diff being committed, so that shipping without review is a hard floor.
23. As an operator at `standard` level, I want a missing or stale review to be a loud nudge rather
    than a block, so that everyday work isn't gated on ceremony.
24. As a solo operator, I want CI to re-run the same floors outside the agent's context, so that a
    skipped local run or a false "green" claim is caught by an independent witness.
25. As a solo operator, I want CI to be advisory with no branch protection, so that I keep the solo
    Git workflow while still getting the witness.
26. As a solo operator, I want CI to fail if the committed config has been gutted below its declared
    level, so that weakening the governance on a repo nobody reviews turns visibly red.
27. As a teammate cloning the repo, I want every role `/build` names to exist as a committed file, so
    that the Loop is self-sufficient without the plugin installed.
28. As a director, I want a committed `coder` subagent primed with TDD-first, scope-restraint, and
    diff-budget discipline, so that dispatched implementation happens in a clean context and the
    directed disciplines are more likely to fire.
29. As a solo operator, I want irreversible actions to rely on the harness's own permission prompt as
    the real floor, so that the Loop doesn't reinvent a guard the harness already provides.
30. As a solo operator, I want Ship to *remind* me to authorise irreversible actions with green CI as
    a precondition, so that the highest-stakes moment is flagged even though it stays directed.
31. As a solo operator, I want to optionally declare `dangerCommands` regexes that a `PreToolUse:
    Bash` hook flags for confirmation, so that project-specific irreversible commands get an extra
    prompt, off by default.
32. As a reader of the docs, I want "enforced by hooks, not by asking" scoped to the true floors and
    the rest labelled directed, so that I don't mistake reminders for guarantees.
33. As a maintainer, I want each planted hook script to be tested as a subprocess against a fixture
    repo, so that the floors' behaviour is verified, not assumed.
34. As a maintainer, I want a structural check on the scaffold output, so that a missing planted file
    or an unregistered hook is caught before release.

## Implementation Decisions

**Modules (planted governance) built or modified — no file paths, described by role:**

- **verify-gate dispatcher** (Stop hook): remove `phase ∈ {build, review}` as a *precondition for the
  floor*. Trigger conditions become: a build is **active** AND the working tree is **dirty** AND
  `level ≠ prototype`. Keep the cheapest-first ordering (lint → types → tests) and the diff-size
  guard against the recorded base. `phase` is retained in state only to drive softer nudges.
- **arming dispatcher** (new `UserPromptSubmit` hook): parse the submitted prompt; if it is a `/build`
  invocation, write `active=true` and `base=<current HEAD>` into the runtime state. Must distinguish
  an actual `/build` slash-command invocation from prose that merely mentions the word "build"
  (User Stories 5–6). Registered in the planted `settings.json`.
- **session-reset dispatcher** (SessionStart hook): unchanged in intent — disarm any leftover active
  state so every session starts dormant (ADR-0005).
- **secret-scan dispatcher** (PreToolUse Write|Edit): unchanged — always-on, state-independent.
- **format dispatcher** (PostToolUse Write|Edit): unchanged — best-effort, never blocks.
- **reviewer subagent**: additionally writes a **verdict artifact** — a committed record containing
  the verdict (APPROVE / REQUEST CHANGES), findings, and the `base..head` SHA range it reviewed.
- **commit-floor dispatcher** (new `PreToolUse` on the git-commit path, or invoked by Ship): at
  `level: production`, block the commit unless a verdict artifact exists whose `base..head` matches
  the diff being committed and whose verdict is APPROVE. At `standard`, emit a nudge instead of
  blocking. Freshness is defined by SHA-range match, not timestamp.
- **coder subagent** (new committed file): primed with TDD-first (RED before GREEN), scope-restraint
  (implement only the task), and diff-budget awareness. Dispatched by the director for context
  hygiene; dispatch remains directed (ceremony), not a floor.
- **dangerCommands dispatcher** (new, optional `PreToolUse: Bash` hook): if the project has declared
  `dangerCommands` regexes in config, flag a matching command for explicit confirmation. Off when the
  list is absent/empty.
- **config schema** (`asdlc.config.json`): add an optional `dangerCommands` array. `level`,
  `commands`, and `gates` semantics unchanged.
- **CI workflow** (`gates.yml`): run the same floor commands as an advisory mirror, plus a
  **config-integrity** step — at `standard`, `commands.lint/types/test` must be non-empty; at
  `production`, the review floor (`gates.review`) must be on. Failing the integrity step fails CI.
- **director prose** (`build.md`) and **house rules** (`CLAUDE.md`): rescope "enforced by hooks" to
  the true floors (secret-scan; verify-gate); state the `level`-moves-floors / `track`-moves-ceremony
  distinction precisely; describe the verdict-artifact and commit-floor behaviour; reference the new
  `coder` role; keep the irreversibility guidance as a directed reminder that defers to the harness
  prompt.
- **scaffold** (`scaffold.sh`) and **hook registrations** (`settings.json`): plant the new files
  (`coder`, new dispatchers) and register `UserPromptSubmit` and the new `PreToolUse` hooks.

**Runtime-state contract (`asdlc-state.json`, gitignored):** `{ active, phase, base, track }`.
`active` and `base` are now written by the arming hook, not only by the director. `phase` and `track`
remain director-written and drive only nudges/ceremony. No session id is tracked (ADR-0005).

**Config/state split preserved:** `asdlc.config.json` stays static-and-committed (the only
stack-specific surface); `asdlc-state.json` stays runtime-and-gitignored. Language-agnostic
dispatchers + stack-specific commands, unchanged as a principle.

## Testing Decisions

**What makes a good test here:** assert only the *external contract* of each hook — its **exit code**
(0 = allow, 2 = block) and its **stderr/stdout message** (substring match) — given a constructed
repo state and a stdin payload. Never assert internal script structure, variable names, or the exact
wording beyond a stable identifying substring. A test should fail if and only if the observable
gate behaviour changes.

**Behavioural seam (primary): hook script as a subprocess.** For each planted `.claude/asdlc/*.sh`,
build a throwaway git repo fixture, write `asdlc-state.json` + `asdlc.config.json`, set the working
tree (clean/dirty, staged diff, base rev), pipe the appropriate hook payload on stdin, and assert
exit code + message. Coverage to include, at minimum:
- verify-gate: dormant when not active; dormant when active+clean; **blocks when active+dirty
  regardless of `phase`**; dormant at `prototype`; blocks on first failing command cheapest-first;
  blocks when diff exceeds `diffSize`.
- arming: a `/build` prompt arms (`active=true`, `base` set); a prompt that only mentions "build"
  does not arm.
- session-reset: leftover `active=true` becomes `active=false` at session start.
- secret-scan: blocks on each provider pattern; allows clean content; active independent of build
  state.
- commit-floor: at `production`, blocks a commit with no/stale/matching-but-REQUEST-CHANGES artifact,
  allows on matching APPROVE; at `standard`, never blocks (nudge only).
- dangerCommands: flags a matching command when configured; no-ops when the list is empty/absent.

**Structural seam (secondary): scaffold output.** Run `scaffold.sh` into a temp dir and assert the
planted set is complete — every role `build.md` names has a committed file (incl. `coder`), and
`settings.json` registers every hook including `UserPromptSubmit` and the new `PreToolUse` hooks.

**Prior art:** none in this repo (no existing tests) — this establishes the seam. Use `bats` if
available, else a minimal plain-bash `run_case` harness that captures exit code + output. Keep the
fixture builder shared across cases.

**Not behaviour-tested:** the directed artifacts (`build.md`/`CLAUDE.md` prose, the `coder` persona)
have no deterministic contract; the structural seam only asserts they exist and are planted.

## Out of Scope

- Any change to the `/asdlc-init` or `/asdlc-adopt` *genesis* UX beyond planting the new files and
  registrations.
- Resumable builds / cross-session build recovery (explicitly rejected — ADR-0005).
- A generalised "irreversible action detector" in the core (explicitly rejected — ADR-0009);
  `dangerCommands` is the opt-in, per-project substitute.
- Enforcing review *quality* or making separation-of-duties an un-fakeable floor (out by ADR-0006 —
  we harden that review was *recorded*, not that it was *good*).
- Branch protection / authoritative CI (rejected — ADR-0007).
- The two minor threads flagged in grilling but not decided: the `on-format.sh` single-file-arg
  convention, and Heavy-track worktrees vs. the single repo-root state/base. Note them; do not change
  them here.

## Further Notes

- The full rationale for every decision lives in `docs/adr/0001`–`0009` and the vocabulary in
  `CONTEXT.md`; use that vocabulary throughout implementation (scaffold, hard floor, directed step,
  verify-gate, arm/disarm, level, track, ceremony, build, effort, verdict artifact, external mirror,
  config-integrity check, coder, dangerCommands).
- This is a multi-session **effort**: decompose into tickets (blockers-first) via `/to-tickets`.
  A natural ticket order: (1) test harness + fixture builder and the structural scaffold check;
  (2) verify-gate rekey (ADR-0002); (3) arming hook (ADR-0003); (4) coder + settings registration
  (ADR-0008); (5) verdict artifact + commit-floor (ADR-0006); (6) config-integrity in CI (ADR-0007);
  (7) dangerCommands (ADR-0009); (8) prose rescope (ADR-0001/0004). Tickets 2–8 each depend on
  ticket 1 (the seam).
- Because the delta *changes the governance the plugin plants*, the plugin's own repo should ideally
  dogfood the new gates once planted — but that adoption pass is a separate effort.
