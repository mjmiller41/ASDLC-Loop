#!/usr/bin/env bash
# ASDLC-Loop — shared gate helpers. Sourced by the on-*.sh dispatchers.
# Resolves the project root, then exposes readers for runtime state + static config.
#
# Two files this reads:
#   .claude/loop-state.json   runtime, gitignored  — is a build active, which phase, base rev
#   .claude/loop.config.json  static,  committed   — build level + stack gate commands

_loop_root() {
  git rev-parse --show-toplevel 2>/dev/null || echo "${CLAUDE_PROJECT_DIR:-$PWD}"
}
LOOP_ROOT="$(_loop_root)"
LOOP_STATE="$LOOP_ROOT/.claude/loop-state.json"
LOOP_CONFIG="$LOOP_ROOT/.claude/loop.config.json"

# loop_active -> 0 if a build is currently armed, else 1.
# Cross-session staleness is handled by the SessionStart hook (on-session.sh),
# which disarms any leftover state at the start of every session — so a crashed
# build never leaves the gates hot. That's why we don't need to match session ids here.
loop_active() {
  [ -f "$LOOP_STATE" ] || return 1
  [ "$(jq -r '.active // false' "$LOOP_STATE" 2>/dev/null)" = "true" ] || return 1
  return 0
}

loop_phase() { jq -r '.phase // ""' "$LOOP_STATE"  2>/dev/null; }
loop_base()  { jq -r '.base  // ""' "$LOOP_STATE"  2>/dev/null; }
loop_level() { cfg '.level'; }

# cfg <jq-filter> -> config value, or empty string if unset/missing.
cfg() { [ -f "$LOOP_CONFIG" ] && jq -r "$1 // empty" "$LOOP_CONFIG" 2>/dev/null || true; }

# phase_in <phase> <allowed...> -> 0 if phase is one of the allowed values.
phase_in() { local p="$1"; shift; local x; for x in "$@"; do [ "$p" = "$x" ] && return 0; done; return 1; }
