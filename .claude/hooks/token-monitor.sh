#!/usr/bin/env bash
# Monitor token usage and alert when approaching 90% of budget
# Called periodically to check thresholds

set -e
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
STATUS_FILE="$ROOT/.claude/session-status.md"

# Read current status file
if [ ! -f "$STATUS_FILE" ]; then
  echo "⚠️  Status file not found: $STATUS_FILE"
  exit 1
fi

# Extract token info from status file (basic parsing)
TOTAL_BUDGET=$(grep "Token Budget" "$STATUS_FILE" | grep -oE '[0-9]+' | head -1)
CURRENT_USAGE=$(grep "Current Usage" "$STATUS_FILE" | grep -oE '[0-9]+' | head -1)

if [ -z "$TOTAL_BUDGET" ] || [ -z "$CURRENT_USAGE" ]; then
  echo "⚠️  Could not parse token info from $STATUS_FILE"
  exit 1
fi

THRESHOLD=$((TOTAL_BUDGET * 90 / 100))
PCT=$((CURRENT_USAGE * 100 / TOTAL_BUDGET))

echo "Token Usage Report:"
echo "  Budget: $TOTAL_BUDGET"
echo "  Current: $CURRENT_USAGE ($PCT%)"
echo "  Threshold (90%): $THRESHOLD"
echo ""

if [ "$CURRENT_USAGE" -ge "$THRESHOLD" ]; then
  echo "🔴 CRITICAL: Approaching token limit (${PCT}% used)"
  echo "   → Export status now: /export-status"
  echo "   → Or begin new session"
  exit 1
elif [ "$CURRENT_USAGE" -gt $((THRESHOLD - 10000)) ]; then
  echo "🟡 WARNING: Getting close to token limit (${PCT}% used)"
  echo "   → Consider exporting status soon"
  exit 0
else
  echo "✓ Comfortable token margin (${PCT}% used)"
  exit 0
fi
