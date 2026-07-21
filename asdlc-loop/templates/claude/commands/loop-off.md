---
name: loop-off
description: Disarm the Director's Loop build-scoped gates immediately (escape hatch). The verify-gate and reviewer nudge go dormant; secrets + format stay always-on.
---

Disarm the build-scoped gates for this project. Run:

```bash
if [ -f .claude/loop-state.json ]; then
  jq '.active=false' .claude/loop-state.json > .claude/loop-state.tmp && mv .claude/loop-state.tmp .claude/loop-state.json
  echo "ASDLC-Loop: build gates disarmed. (secret-scan + format remain always-on)"
else
  echo "ASDLC-Loop: no active build state — nothing to disarm."
fi
```

Use this if a build wedged (e.g. the verify-gate keeps blocking on a failure you're deliberately
deferring). Re-arm later with `/build`.
