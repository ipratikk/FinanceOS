---
description: Smoke-test sonnet-agent on a feature-shaped task.
allowed-tools: Agent
---

# /test-sonnet

Spawn sonnet on a moderately-complex shaped task. Verify:
1. Identity header `[AGENT: SONNET]` appears
2. Plan-then-execute pattern (not pure prose)
3. Does NOT over-read files

## Invoke

```
Agent(subagent_type: general-purpose, prompt: "Acting as sonnet-agent per .claude/agents/sonnet-agent.md. Inspect Packages/FinanceParsers/Sources/FinanceParsers/StatementParser.swift, identify the ParsedStatement struct fields, propose (do NOT implement) ONE missing field that would make multi-currency support easier. Mandatory identity header. Max 6 lines.")
```

## Expected

```
[AGENT: SONNET]
[REASONING: MEDIUM]
[TASK: feature implementation]

Proposed field: `exchangeRate: Decimal?` on ParsedTransaction.
Why: ...
```

Failure modes: missing header, > 12-line response, reading > 3 files.
