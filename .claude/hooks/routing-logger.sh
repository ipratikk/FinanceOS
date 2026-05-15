#!/usr/bin/env bash
# UserPromptSubmit hook: logs every prompt + computed route to .claude/logs/routing.jsonl
# Pairs with escalation-detector. Read-only side effect; never blocks.

set -e
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/routing-lib.sh"

INPUT="$(cat)"
PROMPT=$(printf '%s' "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('prompt',''))" 2>/dev/null || true)
[ -z "$PROMPT" ] && exit 0

RESULT=$(route_prompt "$PROMPT")
AGENT=$(echo "$RESULT" | grep "^AGENT=" | cut -d= -f2)
REASON=$(echo "$RESULT" | grep "^REASON=" | cut -d= -f2-)

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
LOG="$ROOT/.claude/logs/routing.jsonl"
mkdir -p "$(dirname "$LOG")"

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
PROMPT_ESC=$(printf '%s' "$PROMPT" | python3 -c "import json,sys; print(json.dumps(sys.stdin.read())[:500])")
REASON_ESC=$(printf '%s' "$REASON" | python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))")

# Log line
echo "{\"ts\":\"$TS\",\"agent\":\"$AGENT\",\"reason\":$REASON_ESC,\"prompt\":$PROMPT_ESC}" >> "$LOG"

# Cost alert if opus selected
if [ "$AGENT" = "opus" ]; then
  ALERT_LOG="$ROOT/.claude/logs/cost-alerts.jsonl"
  echo "{\"ts\":\"$TS\",\"alert\":\"opus_routed\",\"reason\":$REASON_ESC,\"prompt\":$PROMPT_ESC}" >> "$ALERT_LOG"

  # Check for repeated opus calls in last 10 minutes
  RECENT_OPUS=$(tail -50 "$LOG" 2>/dev/null | grep -c '"agent":"opus"' || echo 0)
  if [ "$RECENT_OPUS" -ge 3 ]; then
    printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"⚠️ OPUS COST ALERT: %s opus routings in recent log. Verify each is genuinely architectural. See .claude/logs/cost-alerts.jsonl"}}\n' "$RECENT_OPUS"
  fi
fi

exit 0
