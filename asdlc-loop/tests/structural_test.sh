#!/usr/bin/env bash
# Structural seam — scaffold into a temp dir and assert the universal core lands intact.
# This is the baseline (ticket 01): it pins today's planted files and hook registrations so
# later tickets that add files/registrations extend a green baseline rather than guessing.
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib/harness.sh"
. "$HERE/lib/fixture.sh"

tmp="$(mktemp -d)"
run_output="$(bash "$SCAFFOLD" "$tmp" 2>&1)"; run_status=$?
STATUS=$run_status OUTPUT=$run_output
assert_status 0 "scaffold.sh exits clean"
assert_contains "OK: universal core scaffolded" "scaffold reports success"

# Planted files — the current universal core.
for f in \
  .claude/asdlc/guard.sh .claude/asdlc/on-write.sh .claude/asdlc/on-stop.sh \
  .claude/asdlc/on-subagent.sh .claude/asdlc/on-session.sh .claude/asdlc/on-format.sh \
  .claude/asdlc/on-prompt.sh \
  .claude/commands/build.md .claude/commands/asdlc-off.md \
  .claude/agents/code-reviewer.md .claude/agents/coder.md \
  .claude/asdlc.config.json .claude/settings.json \
  CLAUDE.md .gitignore .github/workflows/gates.yml docs/specs/.gitkeep
do
  assert_true "planted $f" test -f "$tmp/$f"
done

# Hook scripts are executable.
assert_true "on-write.sh is executable" test -x "$tmp/.claude/asdlc/on-write.sh"

# Every role build.md names by path must be a committed file — a cloned repo must never
# reference an agent that isn't there (ADR-0008). Parse the .claude/agents/<name>.md refs.
build="$tmp/.claude/commands/build.md"
roles="$(grep -oE '\.claude/agents/[A-Za-z0-9_-]+\.md' "$build" | sort -u)"
assert_true "build.md names at least one agent role" test -n "$roles"
for r in $roles; do
  assert_true "role referenced by build.md is planted: $r" test -f "$tmp/$r"
done

# settings.json registers today's hook events.
settings="$tmp/.claude/settings.json"
for ev in UserPromptSubmit PreToolUse PostToolUse Stop SubagentStop SessionStart; do
  assert_true "settings registers $ev" jq -e --arg e "$ev" '.hooks[$e]' "$settings" >/dev/null
done

rm -rf "$tmp"
finish
