#!/usr/bin/env bash
# UserPromptSubmit — deterministic arming. When the human actually invokes `/build`, arm the
# build here (active=true, base=<HEAD>) BEFORE the director acts, so a build the human asked for
# can never be silently left un-armed. Prose that merely mentions "build" must NOT arm — we key
# off a leading `/build` token, not the word. Never blocks the prompt (exit 0). (ADR-0003)
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/guard.sh"
PAYLOAD="$(cat)"

PROMPT="$(printf '%s' "$PAYLOAD" | jq -r '.prompt // empty' 2>/dev/null)"
# A real invocation: the prompt begins with `/build` as its own token (optionally leading space).
printf '%s' "$PROMPT" | grep -Eq '^[[:space:]]*/build([[:space:]]|$)' || exit 0

BASE="$(git -C "$ASDLC_ROOT" rev-parse HEAD 2>/dev/null || echo '')"
mkdir -p "$(dirname "$ASDLC_STATE")"
tmp="$(mktemp)"
# Force active + a fresh base and phase; preserve any existing track the director set earlier.
if [ -f "$ASDLC_STATE" ]; then
  jq --arg base "$BASE" '.active=true | .base=$base | .phase="frame"' "$ASDLC_STATE" >"$tmp" 2>/dev/null \
    && mv "$tmp" "$ASDLC_STATE" || rm -f "$tmp"
else
  jq -n --arg base "$BASE" '{active:true, phase:"frame", base:$base}' >"$tmp" 2>/dev/null \
    && mv "$tmp" "$ASDLC_STATE" || rm -f "$tmp"
fi
exit 0
