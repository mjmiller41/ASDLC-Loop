#!/usr/bin/env bash
# SessionStart — disarm any leftover build state so every session begins with the
# build-scoped gates DORMANT. /build re-arms them. This is what guarantees a crashed or
# abandoned build never leaves the verify-gate hot in a fresh session — without needing
# to track session ids anywhere.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/guard.sh"
cat >/dev/null 2>&1 || true
[ -f "$LOOP_STATE" ] || exit 0
tmp="$(mktemp)"
if jq '.active = false' "$LOOP_STATE" >"$tmp" 2>/dev/null; then mv "$tmp" "$LOOP_STATE"; else rm -f "$tmp"; fi
exit 0
