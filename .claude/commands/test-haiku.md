---
description: Smoke-test haiku-agent on a trivial mechanical task. Verifies haiku responds with identity header.
allowed-tools: Agent
---

# /test-haiku

Spawn haiku-agent with a trivial task. Confirm:
1. Identity header `[AGENT: HAIKU]` appears
2. Response is short (no architectural prose)
3. Task completes in 1-2 tool calls

## Invoke

```
Agent(subagent_type: general-purpose, prompt: "Acting as haiku-agent per .claude/agents/haiku-agent.md. Run `git status` and report the count of modified/untracked files. Mandatory identity header first.")
```

## Expected response shape

```
[AGENT: HAIKU]
[REASONING: LOW]
[TASK: git op]

modified: N, untracked: M
```

If the response is missing the header, missing the JSONL log line, or > 6 lines of prose → **FAIL** (agent ignored its directive).
