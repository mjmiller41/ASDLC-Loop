#!/usr/bin/env bash
# ASDLC-Loop test harness — assertion + subprocess helpers for the hook-script seam.
# Sourced by *_test.sh files; never executed directly. No `set -e` here: assertions
# must keep running after a hook exits non-zero (blocking hooks exit 2 by design).

_tests_run=0
_tests_failed=0

_ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
_fail() { _tests_failed=$((_tests_failed + 1)); printf '  \033[31m✗\033[0m %s\n' "$1"
          [ -n "${2:-}" ] && printf '      %s\n' "$2"; return 0; }

# run_hook_in <repo> <script-path> [payload] -> sets STATUS and OUTPUT (stderr+stdout merged).
# Runs the hook from *inside* the repo so `git rev-parse --show-toplevel` resolves to the fixture.
run_hook_in() {
  local repo="$1" script="$2" payload="${3:-}" tmp
  tmp="$(mktemp)"
  ( cd "$repo" && printf '%s' "$payload" | bash "$script" ) >"$tmp" 2>&1
  STATUS=$?
  OUTPUT="$(cat "$tmp")"
  rm -f "$tmp"
}

assert_status() { # assert_status <expected> <desc>  — checks $STATUS
  _tests_run=$((_tests_run + 1))
  if [ "$STATUS" = "$1" ]; then _ok "$2"
  else _fail "$2" "expected exit $1, got $STATUS — output: ${OUTPUT:-<empty>}"; fi
}

assert_contains() { # assert_contains <needle> <desc>  — checks $OUTPUT
  _tests_run=$((_tests_run + 1))
  case "$OUTPUT" in
    *"$1"*) _ok "$2" ;;
    *)      _fail "$2" "output did not contain: $1 — got: ${OUTPUT:-<empty>}" ;;
  esac
}

assert_not_contains() { # assert_not_contains <needle> <desc>  — checks $OUTPUT
  _tests_run=$((_tests_run + 1))
  case "$OUTPUT" in
    *"$1"*) _fail "$2" "output unexpectedly contained: $1" ;;
    *)      _ok "$2" ;;
  esac
}

assert_true()  { local d="$1"; shift; _tests_run=$((_tests_run + 1))
                 if "$@"; then _ok "$d"; else _fail "$d" "command failed: $*"; fi; }
assert_false() { local d="$1"; shift; _tests_run=$((_tests_run + 1))
                 if "$@"; then _fail "$d" "expected failure: $*"; else _ok "$d"; fi; }

# finish — print the per-file tally and exit non-zero if anything failed.
finish() {
  printf '  — %d checks, %d failed\n' "$_tests_run" "$_tests_failed"
  [ "$_tests_failed" -eq 0 ]
}
