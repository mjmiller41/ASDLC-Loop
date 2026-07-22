#!/usr/bin/env bash
# PreToolUse Bash — the commit-floor. During an active build, guards `git commit` against the review
# verdict artifact written by the code-reviewer. At level=production it BLOCKS (exit 2) a commit unless
# an APPROVE artifact keyed to the current base..HEAD exists; at standard it emits an advisory NUDGE and
# allows; at prototype it is silent. Freshness is by SHA match, not timestamp: when more code lands HEAD
# moves and the old artifact's name no longer matches, so a stale APPROVE stops counting. (ADR-0006)
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/guard.sh"
PAYLOAD="$(cat)"

CMD="$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.command // empty' 2>/dev/null)"
printf '%s' "$CMD" | grep -Eq 'git[[:space:]].*commit' || exit 0   # only guard `git commit`

asdlc_active || exit 0                              # outside a build -> not our concern
LEVEL="$(asdlc_level)"
[ "$LEVEL" = "prototype" ] && exit 0                # prototype: no review floor

BASE="$(asdlc_base)"; [ -n "$BASE" ] || BASE="$(git -C "$ASDLC_ROOT" rev-parse HEAD 2>/dev/null)"
HEAD="$(git -C "$ASDLC_ROOT" rev-parse HEAD 2>/dev/null || echo '')"
ART="$ASDLC_ROOT/.claude/asdlc/verdicts/${BASE}-${HEAD}.json"

# Satisfied only by an APPROVE artifact whose SHA range is exactly the range being committed.
if [ -f "$ART" ] && [ "$(jq -r '.verdict // empty' "$ART" 2>/dev/null)" = "APPROVE" ]; then
  exit 0
fi

MSG="committing $BASE..$HEAD without a current APPROVE. Dispatch the code-reviewer in a clean context — it writes .claude/asdlc/verdicts/<base>-<head>.json. If more code landed since the last review, the old verdict is stale; re-review."
if [ "$LEVEL" = "production" ]; then
  echo "ASDLC-Loop review-floor (production): $MSG" >&2
  exit 2
fi
echo "ASDLC-Loop review-nudge (standard, advisory — not blocking): $MSG" >&2
exit 0
