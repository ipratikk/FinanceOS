#!/usr/bin/env bash
# bootstrap.sh — One-time Claude Code setup for FinanceOS contributors.
#
# Run once after cloning:  bash bootstrap.sh
#
# What it does:
#   1. Checks required CLI tools
#   2. Installs global Claude skills (~/.claude/skills/)
#   3. Verifies project Claude skills (.claude/skills/)
#   4. Makes project hook scripts executable
#   5. Creates runtime directories (.claude/logs/, etc.)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_SKILLS="$HOME/.claude/skills"
PROJECT_SKILLS="$ROOT/.claude/skills"
HOOKS="$ROOT/.claude/hooks"

# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

green()  { printf '\033[0;32m✓ %s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m⚠ %s\033[0m\n' "$*"; }
red()    { printf '\033[0;31m✗ %s\033[0m\n' "$*"; }
header() { printf '\n\033[1m%s\033[0m\n' "$*"; }

MISSING_TOOLS=0

require_tool() {
  local tool="$1"
  local install_hint="$2"
  if command -v "$tool" >/dev/null 2>&1; then
    green "$tool $("$tool" --version 2>/dev/null | head -1 || true)"
  else
    red "$tool not found — $install_hint"
    MISSING_TOOLS=1
  fi
}

# ─────────────────────────────────────────────
# 1. Required tools
# ─────────────────────────────────────────────

header "Checking required tools"

require_tool swiftlint   "brew install swiftlint"
require_tool swiftformat "brew install swiftformat"
require_tool graphify    "pip install graphifyy && graphify install  (see https://graphify.net)"
require_tool gh          "brew install gh  (then: gh auth login)"
require_tool python3     "brew install python"

if [ "$MISSING_TOOLS" -ne 0 ]; then
  yellow "Install missing tools above, then re-run bootstrap.sh"
fi

# ─────────────────────────────────────────────
# 2. Global Claude skills  (~/.claude/skills/)
#    These are tool-level skills that apply across all projects.
#    Written inline here — not copied from the project.
# ─────────────────────────────────────────────

header "Installing global Claude skills"

mkdir -p "$GLOBAL_SKILLS"

install_global_skill_graphify() {
  local dest="$GLOBAL_SKILLS/graphify"
  if [ -d "$dest" ]; then
    yellow "graphify skill already installed at $dest — skipping"
    return
  fi
  mkdir -p "$dest"
  cat > "$dest/SKILL.md" << 'SKILL'
---
name: graphify
description: Regenerate the architectural dependency graph for any project. Run after major refactors, module additions, or cross-package changes. User-only.
disable-model-invocation: true
---

# /graphify

Builds or updates the knowledge graph for the current project.

## Commands

graphify .

## Output

Confirm graphify-out/ updated:
- graphify-out/GRAPH_REPORT.md
- graphify-out/graph.html
- graphify-out/graph.json

## When to run

- After adding or removing a Swift package
- After a cross-module refactor
- When CLAUDE.md instructs architecture analysis and the graph is stale
SKILL
  green "graphify → $dest/SKILL.md"
}

install_global_skill_graphify

# ─────────────────────────────────────────────
# 3. Project Claude skills  (.claude/skills/)
#    These live in the repo — just verify they are present.
# ─────────────────────────────────────────────

header "Verifying project Claude skills"

PROJECT_SKILL_NAMES=(
  build
  commit
  compare-parsers
  lint
  parser-debug
  parser-test
  refactor
  review
  snapshot-update
)

for skill in "${PROJECT_SKILL_NAMES[@]}"; do
  if [ -f "$PROJECT_SKILLS/$skill/SKILL.md" ]; then
    green "$skill"
  else
    red "$skill missing — expected at .claude/skills/$skill/SKILL.md"
  fi
done

# ─────────────────────────────────────────────
# 4. Hook scripts — ensure executable
# ─────────────────────────────────────────────

header "Setting hook permissions"

if [ -d "$HOOKS" ]; then
  # shellcheck disable=SC2012
  count=$(ls "$HOOKS"/*.sh 2>/dev/null | wc -l | tr -d ' ')
  if [ "$count" -gt 0 ]; then
    chmod +x "$HOOKS"/*.sh
    green "$count hook scripts marked executable"
  else
    yellow "No .sh files found in $HOOKS"
  fi
else
  red "Hooks directory not found: $HOOKS"
fi

# ─────────────────────────────────────────────
# 5. Runtime directories
# ─────────────────────────────────────────────

header "Creating runtime directories"

mkdir -p "$ROOT/.claude/logs"
mkdir -p "$ROOT/.claude/reports"
green ".claude/logs"
green ".claude/reports"

# Seed empty JSONL log files so hooks don't fail on first run
for log in routing.jsonl tool-use.jsonl agent-runs.jsonl cost-alerts.jsonl; do
  touch "$ROOT/.claude/logs/$log"
done
green "log files seeded"

# ─────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────

header "Bootstrap complete"

if [ "$MISSING_TOOLS" -ne 0 ]; then
  yellow "Some tools are missing — install them and re-run"
else
  green "All tools present. Claude Code is ready."
fi
