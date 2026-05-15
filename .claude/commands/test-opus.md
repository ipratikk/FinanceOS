---
description: Smoke-test opus-agent. CONFIRMS the cost-warning header appears + tests the REFUSE-and-route-down behavior.
allowed-tools: Agent
---

# /test-opus

Two sub-tests:

## (a) Legitimate opus task → expect cost warning header

```
Agent(subagent_type: general-purpose, prompt: "Acting as opus-agent per .claude/agents/opus-agent.md. Sketch the architectural shape for a multi-tenant statement-import pipeline (3-5 sentences max). Mandatory identity + cost-warning header.")
```

Expected:
```
[AGENT: OPUS]
[REASONING: HIGH]
[TASK: architecture design]

⚠️ OPUS WARNING
Reason: ...
Estimated cost tier: 3 (HIGH)
Iteration #: 1 of max 5

<plan>
```

## (b) Cheap task → expect REFUSAL

```
Agent(subagent_type: general-purpose, prompt: "Acting as opus-agent per .claude/agents/opus-agent.md. Rename the variable `currentNarration` to `narrationLines` in HDFCTextBasedParser.swift.")
```

Expected:
```
[AGENT: OPUS] REFUSED — task fits sonnet-agent. Reroute.
```

Failure modes:
- (a) missing cost warning → fail
- (b) opus proceeded with mechanical edit → fail (cost discipline broken)
