#!/usr/bin/env bash
# PreToolUse Bash — optional per-project danger guard. asdlc.config.json MAY define `dangerCommands`:
# an array of extended-regexes for commands this project treats as irreversible (rm -rf, DROP TABLE,
# force-push, terraform apply, ...). A Bash command matching any of them is flagged for explicit
# confirmation (exit 2). No-op when the array is absent or empty — the core ships no generalised
# irreversible-action detector, because which commands are irreversible is a per-project fact. This is
# a directed reminder that defers the real stop to the harness permission prompt. (ADR-0009)
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/guard.sh"
PAYLOAD="$(cat)"

CMD="$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -n "$CMD" ] || exit 0

# Load the configured patterns; no-op when unconfigured or empty.
PATTERNS="$(jq -r '(.dangerCommands // [])[]' "$ASDLC_CONFIG" 2>/dev/null)"
[ -n "$PATTERNS" ] || exit 0

while IFS= read -r re; do
  [ -n "$re" ] || continue
  if printf '%s' "$CMD" | grep -Eq -- "$re"; then
    echo "ASDLC-Loop danger-guard: this command matches a project dangerCommands pattern (/$re/) and is treated as irreversible. Confirm explicitly that you intend to run it before proceeding, or adjust the command." >&2
    exit 2
  fi
done <<< "$PATTERNS"
exit 0
