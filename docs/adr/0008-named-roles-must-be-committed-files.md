# Every role `/build` names must be a committed file

`build.md` instructs the director to "dispatch a coder subagent per task," but no `coder.md` is
planted — only `code-reviewer.md` exists. A cloned repo therefore has a `build.md` that references a
role that isn't there, quietly breaking the README's "self-sufficient after genesis, works without
the plugin installed" promise.

Rule: **any dispatchable role `build.md` names must exist as a committed file** under
`.claude/agents/`. We plant a `coder.md` accordingly.

The coder and reviewer isolate for *different* reasons: the **reviewer** is isolated for
**independence** (author ≠ approver — a correctness property, and the separation-of-duties
mechanism); the **coder** is isolated for **context hygiene** — keeping the director's context out of
the smart zone across many tasks — and to be a durable home for the directed disciplines TDD-first
(RED before GREEN), scope-restraint, and diff-budget awareness. Priming a coder persona *raises the
odds* those directed steps fire. Dispatching the coder stays ceremony (directed), never a floor.
