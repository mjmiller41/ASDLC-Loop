#!/usr/bin/env bash
# Behavioural seam smoke test — proves run_hook_in drives a real hook as a subprocess and
# reads its exit code + message. Exercises the always-on secret-scan floor (on-write.sh).
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib/harness.sh"
. "$HERE/lib/fixture.sh"

repo="$(new_repo)"
W="$(hook "$repo" on-write.sh)"

run_hook_in "$repo" "$W" '{"tool_input":{"content":"just some harmless text"}}'
assert_status 0 "clean content is allowed"

run_hook_in "$repo" "$W" '{"tool_input":{"content":"aws_key = AKIAIOSFODNN7EXAMPLE"}}'
assert_status 2 "an AWS access key id is blocked"
assert_contains "AWS access key id" "block message names the credential"

# Edit payloads carry the body in .new_string.
run_hook_in "$repo" "$W" '{"tool_input":{"new_string":"token=ghp_0123456789abcdefghijklmnopqrstuvwx"}}'
assert_status 2 "a GitHub token in an edit is blocked"

rm -rf "$repo"
finish
