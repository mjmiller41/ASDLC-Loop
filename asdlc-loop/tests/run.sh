#!/usr/bin/env bash
# ASDLC-Loop test runner. Runs every *_test.sh in this directory as an isolated subprocess and
# exits non-zero if any file reports a failure. This is the single command CI reuses (ticket 06).
#
#   Usage: bash asdlc-loop/tests/run.sh
#
# Requires: bash, git, jq. No bats dependency — a bats port can drop in later at the same seam.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

rc=0
for t in "$HERE"/*_test.sh; do
  [ -e "$t" ] || continue
  printf '══ %s ══\n' "$(basename "$t")"
  bash "$t" || rc=1
  echo
done

if [ "$rc" -eq 0 ]; then echo "ALL PASS"; else echo "FAILURES"; fi
exit "$rc"
