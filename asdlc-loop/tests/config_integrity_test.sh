#!/usr/bin/env bash
# Behavioural seam — the config-integrity tripwire (config-check.sh). Guards the editable-config hole:
# it asserts the committed config still matches its declared level, and exits non-zero (fails CI) when
# it doesn't. standard/production require the gate commands; production also requires the review floor.
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib/harness.sh"
. "$HERE/lib/fixture.sh"

check_cfg() { run_hook_in "$1" "$(hook "$1" config-check.sh)" ''; }
set_cmds()  { config_set "$1" '.commands.lint="lint" | .commands.types="types" | .commands.test="test"'; }

# standard, well-formed -> pass
repo="$(new_repo)"; config_set "$repo" '.level="standard"'; set_cmds "$repo"
check_cfg "$repo"; assert_status 0 "passes on a well-formed standard config"; rm -rf "$repo"

# standard, a command blanked -> fail
repo="$(new_repo)"; config_set "$repo" '.level="standard"'; set_cmds "$repo"
config_set "$repo" '.commands.types=""'
check_cfg "$repo"; assert_status 1 "fails when standard and a gate command is empty"
assert_contains "types" "failure names the missing command"; rm -rf "$repo"

# production, review off -> fail
repo="$(new_repo)"; config_set "$repo" '.level="production"'; set_cmds "$repo"
config_set "$repo" '.gates.review=false'
check_cfg "$repo"; assert_status 1 "fails when production and the review floor is off"
assert_contains "review" "failure names the review floor"; rm -rf "$repo"

# production, well-formed -> pass
repo="$(new_repo)"; config_set "$repo" '.level="production"'; set_cmds "$repo"
config_set "$repo" '.gates.review=true'
check_cfg "$repo"; assert_status 0 "passes on a well-formed production config"; rm -rf "$repo"

# prototype -> pass even with empty commands
repo="$(new_repo)"; config_set "$repo" '.level="prototype"'   # commands stay empty
check_cfg "$repo"; assert_status 0 "passes for prototype (no command requirement)"; rm -rf "$repo"

finish
