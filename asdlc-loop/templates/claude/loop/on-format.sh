#!/usr/bin/env bash
# PostToolUse Write|Edit — format the file that was just written.
# ALWAYS active, best-effort, NEVER blocks (formatting is a tidy, not a gate).
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/guard.sh"
PAYLOAD="$(cat)"
FILE="$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.file_path // .tool_response.filePath // empty')"
[ -n "$FILE" ] || exit 0
FMT="$(cfg '.commands.format')"
[ -n "$FMT" ] || exit 0
# Convention: format command is a prefix; we append the single file path.
( cd "$LOOP_ROOT" && eval "$FMT \"$FILE\"" ) >/dev/null 2>&1 || true
exit 0
