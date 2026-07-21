#!/usr/bin/env bash
# Stop — the verify-gate. BUILD-SCOPED. Runs the config's gate commands cheapest-first
# and blocks the turn from completing (exit 2) if any fail. Dormant unless a build is
# armed, the phase is build|review, the level isn't prototype, and something changed.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/guard.sh"
PAYLOAD="$(cat)"

loop_active || exit 0                                   # no build armed -> dormant
PHASE="$(loop_phase)"
phase_in "$PHASE" build review || exit 0                # wrong phase -> dormant
[ "$(loop_level)" = "prototype" ] && exit 0             # prototype: secrets+format only
[ -n "$(git -C "$LOOP_ROOT" status --porcelain 2>/dev/null)" ] || exit 0  # nothing changed

fail() { echo "ASDLC-Loop verify-gate ($PHASE): $1" >&2; exit 2; }

run() { # run <label> <command>
  local label="$1" cmd="$2" out
  [ -n "$cmd" ] || return 0
  out="$(mktemp)"
  if ! ( cd "$LOOP_ROOT" && eval "$cmd" ) >"$out" 2>&1; then
    local tail_out; tail_out="$(tail -n 20 "$out")"; rm -f "$out"
    fail "$label failed — fix before finishing:
$tail_out"
  fi
  rm -f "$out"
}

# Cheapest first: lint -> types -> tests.
run "lint"  "$(cfg '.commands.lint')"
run "types" "$(cfg '.commands.types')"
run "tests" "$(cfg '.commands.test')"

# Diff-size guard — keep each change reviewable.
MAX="$(cfg '.gates.diffSize')"
if [ -n "$MAX" ] && [ "$MAX" != "0" ]; then
  BASE="$(loop_base)"; [ -n "$BASE" ] || BASE="HEAD"
  CHANGED="$(git -C "$LOOP_ROOT" diff --numstat "$BASE" 2>/dev/null | awk '{a+=$1; d+=$2} END{print a+d+0}')"
  if [ "${CHANGED:-0}" -gt "$MAX" ]; then
    fail "diff is $CHANGED lines (> $MAX). Decompose into smaller units or split the commit."
  fi
fi
exit 0
