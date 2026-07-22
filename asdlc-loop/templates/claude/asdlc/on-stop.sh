#!/usr/bin/env bash
# Stop — the verify-gate. A FLOOR keyed off observable git state, not the director's
# self-reported phase: it runs whenever a build is armed and the working tree is dirty,
# for any phase, and blocks the turn (exit 2) if a gate fails. Dormant when no build is
# armed, when the tree is clean, or when the level is prototype. `phase` is read only to
# label the message and drive softer nudges elsewhere — it does not gate the floor. (ADR-0002)
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/guard.sh"
PAYLOAD="$(cat)"

asdlc_active || exit 0                                   # no build armed -> dormant
PHASE="$(asdlc_phase)"                                   # for the message only; does not gate
[ "$(asdlc_level)" = "prototype" ] && exit 0             # prototype: secrets+format only
[ -n "$(git -C "$ASDLC_ROOT" status --porcelain 2>/dev/null)" ] || exit 0  # clean tree -> dormant

fail() { echo "ASDLC-Loop verify-gate ($PHASE): $1" >&2; exit 2; }

run() { # run <label> <command>
  local label="$1" cmd="$2" out
  [ -n "$cmd" ] || return 0
  out="$(mktemp)"
  if ! ( cd "$ASDLC_ROOT" && eval "$cmd" ) >"$out" 2>&1; then
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
  BASE="$(asdlc_base)"; [ -n "$BASE" ] || BASE="HEAD"
  CHANGED="$(git -C "$ASDLC_ROOT" diff --numstat "$BASE" 2>/dev/null | awk '{a+=$1; d+=$2} END{print a+d+0}')"
  if [ "${CHANGED:-0}" -gt "$MAX" ]; then
    fail "diff is $CHANGED lines (> $MAX). Decompose into smaller units or split the commit."
  fi
fi
exit 0
