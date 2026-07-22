#!/usr/bin/env bash
# ASDLC-Loop test fixtures — build throwaway git repos carrying the planted governance,
# so hook scripts can be exercised as subprocesses against controlled state. Sourced by tests.

_FIX_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$_FIX_SELF/../.." && pwd)"
TPL="$PLUGIN_ROOT/templates"
SCAFFOLD="$PLUGIN_ROOT/scripts/scaffold.sh"

# new_repo -> echoes the path to a fresh git repo (branch main, one base commit) with the
# governance scripts and a default standard config planted under .claude/.
new_repo() {
  local d; d="$(mktemp -d)"
  (
    cd "$d"
    git init -q
    git symbolic-ref HEAD refs/heads/main 2>/dev/null || true
    git config user.email t@example.com
    git config user.name  tester
    mkdir -p .claude/asdlc
    cp "$TPL"/claude/asdlc/*.sh .claude/asdlc/
    cp "$TPL"/claude/asdlc.config.json .claude/asdlc.config.json
    # Runtime state is gitignored in a real scaffold, so writing it never dirties the tree.
    echo '.claude/asdlc-state.json' > .gitignore
    echo seed > README.md
    git add -A >/dev/null
    git commit -qm init
  )
  echo "$d"
}

hook()  { echo "$1/.claude/asdlc/$2"; }              # hook <repo> on-stop.sh -> full path
state() { echo "$1/.claude/asdlc-state.json"; }
config(){ echo "$1/.claude/asdlc.config.json"; }

set_state()  { printf '%s' "$2" > "$(state "$1")"; }  # set_state <repo> <json>
set_config() { printf '%s' "$2" > "$(config "$1")"; } # set_config <repo> <json>

config_set() { # config_set <repo> <jq-filter> — mutate the committed config in place
  local tmp; tmp="$(mktemp)"
  jq "$2" "$(config "$1")" > "$tmp" && mv "$tmp" "$(config "$1")"
}

make_dirty()  { echo "change" >> "$1/work.txt"; }     # leave an uncommitted working-tree change
commit_all()  { ( cd "$1" && git add -A >/dev/null && git commit -qm change ); }  # bank current edits into a clean tree
