#!/usr/bin/env bash
# SubagentStop — BUILD-SCOPED. When a build subagent finishes during the build phase,
# inject a reminder that finished work must pass a clean-context review before Ship.
# The actual reviewer dispatch lives in /build; this hook makes the separation of duties
# hard to silently skip (the author agent may not self-approve).
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/guard.sh"
cat >/dev/null    # drain stdin payload (unused)

asdlc_active || exit 0
phase_in "$(asdlc_phase)" build || exit 0

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"SubagentStop","additionalContext":"ASDLC-Loop: a build subagent just finished. Before advancing to Ship, dispatch the committed reviewer (.claude/agents/code-reviewer.md) in a clean context to review the diff against docs/specs. The agent that wrote the code may not approve it."}}
JSON
exit 0
