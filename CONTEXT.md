# ASDLC Loop

The domain model of the **ASDLC Loop** — a solo-operator, tiered, gated development lifecycle
that this repo's `asdlc-loop` plugin plants into target repos. This glossary fixes the vocabulary
the architecture is designed and discussed in.

## Language

**Scaffold**:
The stance of the whole system: it makes the disciplined path the path of least resistance and
makes deviations loud and visible. It is *not* a sandbox — for a solo operator nothing is truly
un-bypassable, and that is by design.
_Avoid_: Sandbox, guardrail, enforcement layer (when describing the system as a whole).

**Hard floor**:
One of the few genuinely deterministic, non-negotiable checks a turn cannot finish while violating
— secret-scan on write, and the verify-gate on Stop. The only parts that are truly "enforced."
_Avoid_: Gate (too broad — most gates are directed, not hard).

**Directed step**:
A step the `/build` director is *instructed* to perform but which is not deterministically
enforced — the phase sequence, approval gates, TDD-first, separation of duties. The agent can
drift from these; the architecture's job is to make drift visible, not impossible.
_Avoid_: Enforced step, guaranteed step.

**Build**:
A single unit of work driven through the Loop by one `/build` invocation. **Session-scoped**: it is
meant to fit in one context window, and a build not finished in its session is abandoned, not
resumed. Sized small by the diff-size floor and ticket decomposition.
_Avoid_: Run, job, session.

**Effort**:
A body of work too large for one build — decomposed into tickets, each worked as its own fresh
`/build` in a clean context. **The effort is the multi-session grain; the build is not.**
_Avoid_: Project, epic (unless you mean those specifically).

**The Loop**:
The end-to-end sequence a unit of work travels via `/build`: Route → Frame → Design/Plan → Build →
Review → Ship → Learn.
_Avoid_: Pipeline, workflow (reserve for CI).

**Level**:
The repo-wide, committed rigor setting (`prototype` | `standard` | `production`) in
`asdlc.config.json`. **Level is the only dial that moves the floors** — `prototype` removes the
verify-gate; `production` tightens it. Changing it means editing a committed file.
_Avoid_: Mode, tier (when you mean level specifically).

**Track**:
The per-task, in-the-moment path the director picks at Route by blast radius (Quick | Standard |
Heavy). **Track moves only the ceremony** — how much Frame/Plan/Review to perform — and never
touches a floor. A Quick change skips spec and review but still pays the verify-gate.
_Avoid_: Mode, tier, lane.

**Ceremony**:
The directed, bypassable parts of the Loop that a lighter track may skip — Frame, Design/Plan,
Review. Distinct from the floors, which no track may skip.
_Avoid_: Process, overhead.

**Separation of duties**:
The principle that the agent which wrote the code is never the one that approves it. Realised by
dispatching the reviewer as a clean-context subagent. Dispatch is a directed step; what makes it
*visible* is the verdict artifact.
_Avoid_: Independent review, four-eyes.

**Coder**:
The committed subagent (`coder.md`) the director dispatches per task. Isolated for **context
hygiene** — keeping the director out of the smart zone — and primed with TDD-first + scope-restraint
+ diff-budget discipline. Distinct from the reviewer, whose isolation is for **independence**, not
hygiene. Dispatching it is ceremony, not a floor.
_Avoid_: Implementer, worker, builder.

**Verdict artifact**:
The reviewer's written verdict (APPROVE / REQUEST CHANGES + findings), keyed to the exact diff it
reviewed (`base..head` SHAs) so it goes stale automatically when more code lands. Ship reads it; at
`production` level a current APPROVE is a floor, at `standard` its absence is a nudge.
_Avoid_: Review comment, sign-off.

**External mirror**:
The CI job (`gates.yml`): it re-runs the floors *outside the agent's context* to produce a second,
agent-independent observation. It is **advisory** — it witnesses, it does not block a merge (the solo
workflow keeps no branch protection).
_Avoid_: CI gate, enforcement, authority.

**Config-integrity check**:
The one check in the external mirror that guards the editable-config hole: at `standard` the
lint/types/test commands must be non-empty, at `production` the review floor must be on. Gutting the
config to pass the floors turns CI red — the only "reviewer" a config-weakening commit ever sees on a
solo repo.
_Avoid_: Lint (it is not a lint of code — it lints the governance config).

**dangerCommands**:
An optional, per-project list of regexes in `asdlc.config.json` for commands a project deems
irreversible (deploy, migrate, live money). A `PreToolUse: Bash` hook flags matches for explicit
confirmation. Off by default — *which* commands are irreversible is a per-project fact the
language-agnostic core cannot know.
_Avoid_: Blocklist, denylist.

**Verify-gate**:
The Stop-hook hard floor that runs lint → types → tests → diff-size and blocks a turn from
finishing while they fail. Fires on **observable git state** (a build is active and the working
tree is dirty), not on the director's self-reported phase.
_Avoid_: Test gate, CI gate.

**Arm / Disarm**:
To arm is to mark a build active in `asdlc-state.json` so the build-scoped floors go live; disarm
sets it dormant. Arming happens **deterministically** when `/build` is invoked (not as a directed
step), so a build the human asked for can never be silently un-armed. A fresh session always begins
disarmed; `/asdlc-off` disarms on demand.
_Avoid_: Enable/disable, start/stop.
