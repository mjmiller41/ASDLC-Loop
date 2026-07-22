#!/usr/bin/env bash
# Config-integrity tripwire. Guards the editable-config hole: CI runs the config's OWN commands, so
# gutting the config (blanking the gate commands, or dropping the level to prototype) would sail
# through a green CI silently. This asserts the committed config still matches its declared level and
# exits non-zero (fails CI) when it doesn't — the only "reviewer" a quiet config-weakening commit ever
# sees on a solo repo. Advisory: it fails CI, it does not enforce branch protection. (ADR-0007)
#
# Run in CI (gates.yml) and locally: bash .claude/asdlc/config-check.sh
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/guard.sh"

fail() { echo "ASDLC-Loop config-integrity: $1" >&2; exit 1; }

LEVEL="$(asdlc_level)"
require_commands() {
  local key
  for key in lint types test; do
    [ -n "$(cfg ".commands.$key")" ] || fail "level=$LEVEL requires commands.$key to be set"
  done
}

case "$LEVEL" in
  production)
    [ "$(jq -r '.gates.review // false' "$ASDLC_CONFIG" 2>/dev/null)" = "true" ] \
      || fail "level=production requires the review floor (gates.review=true)"
    require_commands
    ;;
  standard)
    require_commands
    ;;
  prototype|"")
    : ;;                       # prototype imposes no command requirement
  *)
    fail "unknown level: $LEVEL (expected prototype|standard|production)" ;;
esac

echo "config-integrity OK (level=${LEVEL:-unset})"
exit 0
