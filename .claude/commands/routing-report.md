---
description: Observability dashboard — summarize agent activity from .claude/logs/. Token cost overview, opus usage rate, timeline.
allowed-tools: Bash
---

# /routing-report

Read-only summary of multi-agent activity. No LLM in the loop.

## Run

```bash
.claude/hooks/routing-report.sh
```

## What it prints

```
=== Routing Report (last 24h) ===
Total prompts: <N>
By agent:
  haiku:  <N> (<pct>%)
  sonnet: <N> (<pct>%)
  opus:   <N> (<pct>%)

Cost alerts: <N>
  - <ts> opus_routed: <reason>

Recent timeline (last 10):
  <ts> [haiku] format request — "..."
  <ts> [sonnet] integration — "..."
  <ts> [opus] parser failure — "..."

Tool use:
  Edit:  <N> (<bytes>k)
  Bash:  <N>
  Read:  <N>
  Write: <N>

Hard-rule status: <PASS|FAIL>
```

## Health checks

- opus ratio > 30% → flag as warning ("opus overuse")
- > 5 opus in 1h → flag as critical
- > 50 prompts with no haiku → flag (routing broken or session pattern unusual)
