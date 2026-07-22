#!/usr/bin/env bash
# Behavioural seam — deterministic arming (on-prompt.sh). A real `/build` invocation writes
# active=true and base=HEAD into runtime state itself; prose that merely mentions "build" does not.
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib/harness.sh"
. "$HERE/lib/fixture.sh"

# submit <repo> <prompt> — feed a UserPromptSubmit payload to the arming hook.
submit() { run_hook_in "$1" "$(hook "$1" on-prompt.sh)" "$(jq -n --arg p "$2" '{prompt:$p}')"; }

# --- a real /build invocation arms the build ---
repo="$(new_repo)"
submit "$repo" '/build add a login form'
assert_status 0 "arming hook never blocks the prompt"
assert_true  "state is written"        test -f "$(state "$repo")"
assert_true  "build is armed active"   test "$(get_state "$repo" '.active')" = "true"
assert_true  "base is pinned to HEAD"  test "$(get_state "$repo" '.base')" = "$(git_head "$repo")"
rm -rf "$repo"

# --- bare /build with no args still arms ---
repo="$(new_repo)"
submit "$repo" '/build'
assert_true "bare /build arms" test "$(get_state "$repo" '.active')" = "true"
rm -rf "$repo"

# --- prose mentioning "build" does NOT arm ---
repo="$(new_repo)"
submit "$repo" 'we should build a login form next'
assert_status 0 "prose prompt never blocks"
assert_false "prose does not arm (no active build)" test "$(get_state "$repo" '.active')" = "true"
rm -rf "$repo"

# --- a word that merely starts with 'build' does not arm ---
repo="$(new_repo)"
submit "$repo" '/builder please scaffold something'
assert_false "/builder is not /build" test "$(get_state "$repo" '.active')" = "true"
rm -rf "$repo"

finish
