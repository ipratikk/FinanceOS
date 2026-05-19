#!/usr/bin/env bash
# Helper: prints the correct Agent tool call for a given agent + task.
# Use when subagent_type 'haiku-agent' isn't registered (see VERIFICATION.md).
#
# Usage:
#   .claude/hooks/spawn.sh haiku  "run swift build and report errors"
#   .claude/hooks/spawn.sh sonnet "implement TXTStatementParser following CSVStatementParser pattern"
#   .claude/hooks/spawn.sh opus   "design the dedup engine for multi-currency"
#
# Output: a ready-to-paste Agent({...}) invocation.

set -e
AGENT="$1"
TASK="${2:-}"

case "$AGENT" in
  haiku|sonnet|opus) ;;
  *) echo "Usage: $0 <haiku|sonnet|opus> \"<task>\""; exit 1 ;;
esac

if [ -z "$TASK" ]; then
  echo "Usage: $0 <haiku|sonnet|opus> \"<task>\""
  exit 1
fi

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
AGENT_MD="$ROOT/.claude/agents/${AGENT}-agent.md"
[ ! -f "$AGENT_MD" ] && { echo "Missing $AGENT_MD"; exit 1; }

# Print Agent invocation template
cat <<EOF
Agent({
  description: "<3-5 word desc>",
  subagent_type: "general-purpose",
  model: "$AGENT",
  prompt: \`Acting as ${AGENT}-agent per .claude/agents/${AGENT}-agent.md.

MANDATORY: respond with the identity header defined in that file BEFORE any other content.

Task: $TASK

(after completing the task, append a JSONL line to .claude/logs/agent-runs.jsonl per the agent.md spec)
\`
})
EOF
