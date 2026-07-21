#!/usr/bin/env bash
# ASDLC-Loop — deterministic universal-core scaffold.
# Plants the language-agnostic governance into a target repo. Idempotent: safe to re-run,
# never clobbers an existing asdlc.config.json / CLAUDE.md, and merges rather than overwrites
# an existing .claude/settings.json (it emits MERGE_NEEDED for the caller to handle).
#
# Usage: scaffold.sh <target-dir> [level]     level = prototype|standard|production (default standard)
set -euo pipefail

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SELF/.." && pwd)"
TPL="$PLUGIN_ROOT/templates"

TARGET="${1:?usage: scaffold.sh <target-dir> [level]}"
LEVEL="${2:-standard}"

mkdir -p "$TARGET"
cd "$TARGET"
# Fresh repos always start on 'main' (portable across git versions; set before first commit).
if [ ! -d .git ]; then
  git init -q
  git symbolic-ref HEAD refs/heads/main 2>/dev/null || true
fi

mkdir -p .claude/asdlc .claude/commands .claude/agents docs/specs .github/workflows

# Our own files — safe to (re)write on every run.
cp "$TPL"/claude/asdlc/*.sh        .claude/asdlc/
cp "$TPL"/claude/commands/*.md    .claude/commands/
cp "$TPL"/claude/agents/*.md      .claude/agents/
chmod +x .claude/asdlc/*.sh

# Config — create once, then it's yours; only set the level on first creation.
if [ ! -f .claude/asdlc.config.json ]; then
  cp "$TPL/claude/asdlc.config.json" .claude/asdlc.config.json
  tmp="$(mktemp)"; jq --arg l "$LEVEL" '.level=$l' .claude/asdlc.config.json >"$tmp" && mv "$tmp" .claude/asdlc.config.json
fi

# settings.json — never clobber existing hooks; signal a merge instead.
if [ -f .claude/settings.json ]; then
  echo "MERGE_NEEDED: .claude/settings.json already exists — merge the hooks from $TPL/claude/settings.json"
else
  cp "$TPL/claude/settings.json" .claude/settings.json
fi

# .gitignore — append our block once.
if [ -f .gitignore ]; then
  grep -q 'ASDLC-Loop' .gitignore || cat "$TPL/gitignore" >> .gitignore
else
  cp "$TPL/gitignore" .gitignore
fi

# CLAUDE.md — create if absent; never overwrite the user's.
if [ ! -f CLAUDE.md ]; then cp "$TPL/CLAUDE.md" CLAUDE.md; else echo "NOTE: CLAUDE.md exists — consider merging $TPL/CLAUDE.md"; fi

# CI backstop + specs dir.
[ -f .github/workflows/gates.yml ] || cp "$TPL/github/workflows/gates.yml" .github/workflows/gates.yml
[ -f docs/specs/.gitkeep ] || : > docs/specs/.gitkeep

echo "OK: universal core scaffolded into $TARGET (level=$LEVEL)"
