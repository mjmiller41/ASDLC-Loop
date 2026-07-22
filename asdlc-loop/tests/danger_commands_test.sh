#!/usr/bin/env bash
# Behavioural seam — the optional danger guard (on-danger.sh). When asdlc.config.json defines a
# dangerCommands array of regexes, a Bash command matching any of them is flagged for explicit
# confirmation (exit 2). No-op when the array is absent or empty.
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib/harness.sh"
. "$HERE/lib/fixture.sh"

danger() { run_hook_in "$1" "$(hook "$1" on-danger.sh)" "$(jq -n --arg c "$2" '{tool_input:{command:$c}}')"; }

# configured + matches -> block
repo="$(new_repo)"; config_set "$repo" '.dangerCommands=["rm -rf ","git push .*--force"]'
danger "$repo" 'rm -rf /tmp/data'
assert_status 2 "flags a command matching a configured dangerCommands pattern"
assert_contains "danger" "message identifies it as a danger-guard block"
rm -rf "$repo"

# configured + a second pattern matches -> block
repo="$(new_repo)"; config_set "$repo" '.dangerCommands=["rm -rf ","git push .*--force"]'
danger "$repo" 'git push origin main --force'
assert_status 2 "flags a match against any configured pattern"
rm -rf "$repo"

# configured + no match -> allow
repo="$(new_repo)"; config_set "$repo" '.dangerCommands=["rm -rf ","git push .*--force"]'
danger "$repo" 'ls -la'
assert_status 0 "allows a command matching no configured pattern"
rm -rf "$repo"

# unconfigured (no dangerCommands key) -> allow even a scary command
repo="$(new_repo)"; config_set "$repo" 'del(.dangerCommands)'   # genuinely absent
danger "$repo" 'rm -rf /'
assert_status 0 "no-op when dangerCommands is absent"
rm -rf "$repo"

# empty array -> allow
repo="$(new_repo)"; config_set "$repo" '.dangerCommands=[]'
danger "$repo" 'rm -rf /'
assert_status 0 "no-op when dangerCommands is empty"
rm -rf "$repo"

finish
