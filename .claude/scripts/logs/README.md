# scripts/logs/

Log reading and summarization scripts.

## Scripts

- `summary.sh` — tail + summarize agent-runs.jsonl, routing.jsonl, cost-alerts.jsonl.
- `cost.sh` — opus usage rate, cost alerts, threshold checks.

## Log files (in .claude/logs/)

- `agent-runs.jsonl` — per-agent task completions (written by each agent per identity contract)
- `routing.jsonl` — every prompt + computed route (written by routing-logger hook)
- `cost-alerts.jsonl` — opus-routed prompts flagged for cost review
- `tool-use.jsonl` — every tool call + response size

## Output format

JSONL. Each line is independent. Never rely on line ordering within a session.
