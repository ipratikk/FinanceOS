---
description: End-to-end test of haiku→sonnet and sonnet→opus escalation paths.
allowed-tools: Agent, Bash
---

# /test-escalation

Verifies escalation works as a chain.

## Test 1: haiku → sonnet

Spawn haiku with a task that should trigger escalation:

```
Agent(subagent_type: general-purpose, prompt: "Acting as haiku-agent. Task: 'Make HDFCTextBasedParser fully Sendable.' Per your escalation rules (.claude/agents/haiku-agent.md item 5), this requires concurrency reasoning. Do NOT attempt — emit the ESCALATE format and stop.")
```

Expected response:
```
[AGENT: HAIKU]
[REASONING: LOW]
[TASK: mechanical edit]

ESCALATE: haiku → opus
Reason: Sendable conformance requires actor-isolation reasoning
Context: HDFCTextBasedParser.swift, no obvious mechanical fix
```

## Test 2: sonnet → haiku (de-escalation)

```
Agent(subagent_type: general-purpose, prompt: "Acting as sonnet-agent. You just finished designing a 3-file rename. Per de-escalation rules, hand the mechanical apply step down to haiku. Emit the DELEGATE format only.")
```

Expected:
```
[AGENT: SONNET]
[REASONING: MEDIUM]
[TASK: medium refactor]

DELEGATE: sonnet → haiku
Reason: design done, only mechanical changes remain
Handoff: apply this rename across these 3 files: ...
```

## Test 3: opus refuses cheap task

See `/test-opus` test (b).

## Pass criteria

All three return the expected control-flow keyword (ESCALATE/DELEGATE/REFUSED) within their identity header.

## Log inspection

```bash
tail -20 .claude/logs/agent-runs.jsonl 2>/dev/null | python3 -m json.tool || echo "(no logs yet)"
```
