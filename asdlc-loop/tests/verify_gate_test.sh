#!/usr/bin/env bash
# Behavioural seam — the verify-gate (on-stop.sh) is a floor keyed off observable git state:
# it fires when a build is active and the tree is dirty, for ANY phase; dormant otherwise.
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib/harness.sh"
. "$HERE/lib/fixture.sh"

# armed <repo> <phase> — mark a build active at the given phase, base=HEAD.
armed() { set_state "$1" "{\"active\":true,\"phase\":\"$2\",\"base\":\"HEAD\"}"; }

# --- fires on active + dirty, regardless of phase ---
repo="$(new_repo)"; S="$(hook "$repo" on-stop.sh)"
config_set "$repo" '.commands.lint = "false"'
armed "$repo" build; make_dirty "$repo"
run_hook_in "$repo" "$S" '{}'
assert_status 2 "blocks when active + dirty at phase=build"
assert_contains "lint" "block message names the failing gate"

# The regression this ticket targets: a non-build/review phase must NOT make the floor dormant.
armed "$repo" learn
run_hook_in "$repo" "$S" '{}'
assert_status 2 "blocks when active + dirty at phase=learn (phase does not gate the floor)"
rm -rf "$repo"

# --- dormant when not active ---
repo="$(new_repo)"; S="$(hook "$repo" on-stop.sh)"
config_set "$repo" '.commands.lint = "false"'
set_state "$repo" '{"active":false,"phase":"build","base":"HEAD"}'
make_dirty "$repo"
run_hook_in "$repo" "$S" '{}'
assert_status 0 "dormant when no build is active"
rm -rf "$repo"

# --- dormant when active but tree is clean ---
repo="$(new_repo)"; S="$(hook "$repo" on-stop.sh)"
config_set "$repo" '.commands.lint = "false"'; commit_all "$repo"  # bank config -> tree clean
armed "$repo" build   # no make_dirty -> clean tree
run_hook_in "$repo" "$S" '{}'
assert_status 0 "dormant when active but working tree is clean"
rm -rf "$repo"

# --- dormant at prototype level ---
repo="$(new_repo)"; S="$(hook "$repo" on-stop.sh)"
config_set "$repo" '.level = "prototype" | .commands.lint = "false"'
armed "$repo" build; make_dirty "$repo"
run_hook_in "$repo" "$S" '{}'
assert_status 0 "dormant at prototype level (secrets + format only)"
rm -rf "$repo"

# --- cheapest-first, block on first failure ---
repo="$(new_repo)"; S="$(hook "$repo" on-stop.sh)"
config_set "$repo" '.commands.lint = "echo LINTRAN; false" | .commands.types = "echo TYPESRAN; false"'
armed "$repo" build; make_dirty "$repo"
run_hook_in "$repo" "$S" '{}'
assert_status 2 "blocks on the first failing gate"
assert_contains "LINTRAN" "lint ran (cheapest first)"
assert_not_contains "TYPESRAN" "types did not run after lint failed"
rm -rf "$repo"

# --- diff-size guard still fires against the recorded base ---
repo="$(new_repo)"; S="$(hook "$repo" on-stop.sh)"
config_set "$repo" '.gates.diffSize = 1'   # commands stay empty -> only the size guard can block
armed "$repo" build
printf 'a\nb\nc\nd\n' >> "$repo/README.md"  # tracked change > 1 line vs base
run_hook_in "$repo" "$S" '{}'
assert_status 2 "blocks when the diff against base exceeds diffSize"
assert_contains "diff is" "block message reports the oversized diff"
rm -rf "$repo"

finish
