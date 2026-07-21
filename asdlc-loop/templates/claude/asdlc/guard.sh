#!/usr/bin/env bash
# ASDLC-Loop — shared gate helpers. Sourced by the on-*.sh dispatchers.
# Resolves the project root, then exposes readers for runtime state + static config.
#
# Two files this reads:
#   .claude/asdlc-state.json   runtime, gitignored  — is a build active, which phase, base rev
#   .claude/asdlc.config.json  static,  committed   — build level + stack gate commands

_asdlc_root() {
  git rev-parse --show-toplevel 2>/dev/null || echo "${CLAUDE_PROJECT_DIR:-$PWD}"
}
ASDLC_ROOT="$(_asdlc_root)"
ASDLC_STATE="$ASDLC_ROOT/.claude/asdlc-state.json"
ASDLC_CONFIG="$ASDLC_ROOT/.claude/asdlc.config.json"

# asdlc_active -> 0 if a build is currently armed, else 1.
# Cross-session staleness is handled by the SessionStart hook (on-session.sh),
# which disarms any leftover state at the start of every session — so a crashed
# build never leaves the gates hot. That's why we don't need to match session ids here.
asdlc_active() {
  [ -f "$ASDLC_STATE" ] || return 1
  [ "$(jq -r '.active // false' "$ASDLC_STATE" 2>/dev/null)" = "true" ] || return 1
  return 0
}

asdlc_phase() { jq -r '.phase // ""' "$ASDLC_STATE"  2>/dev/null; }
asdlc_base()  { jq -r '.base  // ""' "$ASDLC_STATE"  2>/dev/null; }
asdlc_level() { cfg '.level'; }

# cfg <jq-filter> -> config value, or empty string if unset/missing.
cfg() { [ -f "$ASDLC_CONFIG" ] && jq -r "$1 // empty" "$ASDLC_CONFIG" 2>/dev/null || true; }

# phase_in <phase> <allowed...> -> 0 if phase is one of the allowed values.
phase_in() { local p="$1"; shift; local x; for x in "$@"; do [ "$p" = "$x" ] && return 0; done; return 1; }
