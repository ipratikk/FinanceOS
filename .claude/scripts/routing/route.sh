#!/usr/bin/env bash
# route.sh <prompt>
# Print routing decision for a task. Read-only. Always exits 0.
# Output:
#   Task: <prompt>
#   Agent: <haiku|sonnet|opus>
#   Reason: <text>
#   Cost tier: <1=cheap, 2=mid, 3=expensive>

set -e
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"

PROMPT="${1:-}"
if [ -z "$PROMPT" ]; then
  echo "Usage: route.sh \"<task description>\""
  exit 1
fi

RESULT=$(route_prompt "$PROMPT")
AGENT=$(echo "$RESULT" | grep "^AGENT=" | cut -d= -f2)
REASON=$(echo "$RESULT" | grep "^REASON=" | cut -d= -f2-)

case "$AGENT" in
  haiku)  TIER="1 (cheap)" ;;
  sonnet) TIER="2 (mid)" ;;
  opus)   TIER="3 (expensive)" ;;
  *)      TIER="?" ;;
esac

echo "Task:      $PROMPT"
echo "Agent:     $AGENT"
echo "Reason:    $REASON"
echo "Cost tier: $TIER"
