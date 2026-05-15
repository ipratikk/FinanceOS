#!/usr/bin/env bash
# Observability dashboard. Reads .claude/logs/ and prints summary.

set -e
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
LOGS="$ROOT/.claude/logs"
ROUTING="$LOGS/routing.jsonl"
ALERTS="$LOGS/cost-alerts.jsonl"
TOOLS="$LOGS/tool-use.jsonl"

if [ ! -f "$ROUTING" ]; then
  echo "No routing log yet at $ROUTING"
  exit 0
fi

echo "=== Routing Report ==="
echo "Log: $ROUTING"
echo

# Counts by agent
TOTAL=$(wc -l < "$ROUTING" | tr -d ' ')
HAIKU=$(grep -c '"agent":"haiku"' "$ROUTING" 2>/dev/null || echo 0)
SONNET=$(grep -c '"agent":"sonnet"' "$ROUTING" 2>/dev/null || echo 0)
OPUS=$(grep -c '"agent":"opus"' "$ROUTING" 2>/dev/null || echo 0)

echo "Total prompts: $TOTAL"
if [ "$TOTAL" -gt 0 ]; then
  echo "By agent:"
  echo "  haiku:  $HAIKU ($((HAIKU*100/TOTAL))%)"
  echo "  sonnet: $SONNET ($((SONNET*100/TOTAL))%)"
  echo "  opus:   $OPUS ($((OPUS*100/TOTAL))%)"
fi
echo

# Cost alerts
ALERT_COUNT=0
if [ -f "$ALERTS" ]; then
  ALERT_COUNT=$(wc -l < "$ALERTS" | tr -d ' ')
fi
echo "Cost alerts: $ALERT_COUNT"
if [ "$ALERT_COUNT" -gt 0 ]; then
  tail -5 "$ALERTS" | python3 -c "
import sys, json
for line in sys.stdin:
  try:
    d = json.loads(line)
    print(f\"  {d.get('ts','?')} {d.get('alert','?')}: {d.get('reason','?')}\")
  except: pass"
fi
echo

# Timeline
echo "Recent timeline (last 10):"
tail -10 "$ROUTING" | python3 -c "
import sys, json
for line in sys.stdin:
  try:
    d = json.loads(line)
    prompt = d.get('prompt','')[:60].replace('\n',' ')
    print(f\"  {d.get('ts','?')} [{d.get('agent','?')}] {d.get('reason','?')} — \\\"{prompt}\\\"\")
  except: pass"
echo

# Tool use
if [ -f "$TOOLS" ]; then
  echo "Tool use:"
  python3 - <<EOF
import json
from collections import Counter
c = Counter()
b = Counter()
with open("$TOOLS") as f:
  for line in f:
    try:
      d = json.loads(line)
      tool = d.get('tool','?')
      c[tool] += 1
      b[tool] += d.get('bytes',0)
    except: pass
for tool, n in c.most_common():
  print(f"  {tool}:  {n} ({b[tool]//1024}k)")
EOF
fi
echo

# Health
echo "── Health ──"
if [ "$TOTAL" -gt 0 ]; then
  OPUS_PCT=$((OPUS*100/TOTAL))
  if [ "$OPUS_PCT" -gt 30 ]; then
    echo "🔴 OPUS RATIO HIGH: $OPUS_PCT% (threshold 30%)"
  elif [ "$OPUS_PCT" -gt 15 ]; then
    echo "🟡 opus ratio: $OPUS_PCT% (monitor)"
  else
    echo "✓ opus ratio: $OPUS_PCT% (healthy)"
  fi
fi

# Hard-rule status from simulator
SIM_RESULT=$("$ROOT/.claude/hooks/routing-simulator.sh" 2>&1 | tail -3 | head -1)
echo "Hard-rule sim: $SIM_RESULT"
