#!/usr/bin/env bash
# PreToolUse Write|Edit — refuse to write obvious secrets to disk.
# ALWAYS active (NOT build-scoped): a credential must never land on disk, build or not.
# Exit 2 blocks the tool call and feeds the message back to Claude.
set -uo pipefail
PAYLOAD="$(cat)"
# Write puts new file body in .content; Edit puts the replacement in .new_string.
CONTENT="$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null)"
[ -n "$CONTENT" ] || exit 0

match=""
scan() { printf '%s' "$CONTENT" | grep -Eq "$1" && match="$2"; }
# High-signal provider patterns only — kept conservative to avoid false positives that
# would tempt you to disable the gate. Add project-specific patterns as needed.
scan 'sk_live_[0-9a-zA-Z]{16,}'          'a Stripe live secret key'
scan 'AKIA[0-9A-Z]{16}'                  'an AWS access key id'
scan '\-\-\-\-\-BEGIN[ A-Z]*PRIVATE KEY' 'a PEM private key'
scan 'gh[pousr]_[0-9A-Za-z]{20,}'        'a GitHub token'
scan 'xox[baprs]-[0-9A-Za-z-]{10,}'      'a Slack token'

if [ -n "$match" ]; then
  echo "ASDLC-Loop secret-gate: refused this write — it contains what looks like $match. Move it to an environment variable or secret store, not source." >&2
  exit 2
fi
exit 0
