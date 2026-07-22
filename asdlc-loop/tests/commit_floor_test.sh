#!/usr/bin/env bash
# Behavioural seam — the commit-floor (on-commit.sh). During an active build it guards `git commit`
# against the review verdict artifact: production BLOCKS without a current APPROVE keyed to base..HEAD,
# standard NUDGES, prototype is silent. Freshness is by SHA match (more code lands -> stale).
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib/harness.sh"
. "$HERE/lib/fixture.sh"

arm_at() { set_state "$1" "{\"active\":true,\"phase\":\"review\",\"base\":\"$2\"}"; }
write_verdict() { # write_verdict <repo> <base> <head> <verdict>
  mkdir -p "$1/.claude/asdlc/verdicts"
  jq -n --arg b "$2" --arg h "$3" --arg v "$4" '{base:$b,head:$h,verdict:$v}' \
    > "$1/.claude/asdlc/verdicts/$2-$3.json"
}
COMMIT='{"tool_input":{"command":"git add -A && git commit -m wip"}}'
run_commit() { run_hook_in "$1" "$(hook "$1" on-commit.sh)" "$COMMIT"; }

# ---------- production ----------
# no artifact -> block
repo="$(new_repo)"; config_set "$repo" '.level="production"'; b="$(git_head "$repo")"; arm_at "$repo" "$b"
run_commit "$repo"
assert_status 2 "production: blocks a commit with no verdict artifact"
assert_contains "review" "block message mentions review"
rm -rf "$repo"

# REQUEST CHANGES -> block
repo="$(new_repo)"; config_set "$repo" '.level="production"'; b="$(git_head "$repo")"; arm_at "$repo" "$b"
write_verdict "$repo" "$b" "$b" "REQUEST CHANGES"
run_commit "$repo"
assert_status 2 "production: blocks when the matching artifact says REQUEST CHANGES"
rm -rf "$repo"

# stale: APPROVE for an earlier head, then more code lands -> block
repo="$(new_repo)"; config_set "$repo" '.level="production"'; b="$(git_head "$repo")"; arm_at "$repo" "$b"
write_verdict "$repo" "$b" "$b" "APPROVE"     # approved at head=b
make_dirty "$repo"; commit_all "$repo"        # more code lands -> HEAD advances past b
run_commit "$repo"
assert_status 2 "production: blocks when the APPROVE is stale (more code landed)"
rm -rf "$repo"

# current matching APPROVE -> allow
repo="$(new_repo)"; config_set "$repo" '.level="production"'; b="$(git_head "$repo")"; arm_at "$repo" "$b"
write_verdict "$repo" "$b" "$b" "APPROVE"
run_commit "$repo"
assert_status 0 "production: allows a commit on a current matching APPROVE"
rm -rf "$repo"

# ---------- standard ----------
# no artifact -> nudge, never block
repo="$(new_repo)"; b="$(git_head "$repo")"; arm_at "$repo" "$b"   # default level standard
run_commit "$repo"
assert_status 0 "standard: never blocks (nudge only) without a verdict"
assert_contains "nudge" "standard emits an advisory nudge"
rm -rf "$repo"

# ---------- scoping ----------
# not a commit command -> ignored
repo="$(new_repo)"; config_set "$repo" '.level="production"'; b="$(git_head "$repo")"; arm_at "$repo" "$b"
run_hook_in "$repo" "$(hook "$repo" on-commit.sh)" '{"tool_input":{"command":"git status"}}'
assert_status 0 "non-commit git command is ignored"
rm -rf "$repo"

# no build active -> dormant even at production
repo="$(new_repo)"; config_set "$repo" '.level="production"'
set_state "$repo" '{"active":false,"phase":"review","base":"x"}'
run_commit "$repo"
assert_status 0 "dormant when no build is active"
rm -rf "$repo"

# prototype -> silent
repo="$(new_repo)"; config_set "$repo" '.level="prototype"'; b="$(git_head "$repo")"; arm_at "$repo" "$b"
run_commit "$repo"
assert_status 0 "prototype: no review floor"
rm -rf "$repo"

finish
