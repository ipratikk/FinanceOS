#!/usr/bin/env bash
# PostToolUse hook: logs which tool ran + how big the result was.
# Helps spot when opus is doing too much (Bash, Edit, Write) vs reading.

set -e
INPUT="$(cat)"
TOOL=$(printf '%s' "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || true)
SIZE=$(printf '%s' "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(str(d.get('tool_response',''))))" 2>/dev/null || echo 0)

[ -z "$TOOL" ] && exit 0

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
LOG="$ROOT/.claude/logs/tool-use.jsonl"
mkdir -p "$(dirname "$LOG")"

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "{\"ts\":\"$TS\",\"tool\":\"$TOOL\",\"bytes\":$SIZE}" >> "$LOG"

exit 0
