---
description: Run the routing simulator. 28 canned prompts → expected vs actual agent. Reports pass/fail + opus leaks.
allowed-tools: Bash
---

# /test-routing

Deterministic routing verification. No LLM in the loop — pure shell regex match.

## Run

```bash
.claude/hooks/routing-simulator.sh
```

## Exit codes

- `0` — all pass, no opus leaks
- `1` — at least one failure OR opus leaked to a cheap prompt

## Adding new test cases

Edit `.claude/hooks/routing-simulator.sh`, append to `CASES=(...)` as `"prompt|expected-agent"`.

## Failure investigation

If a prompt routes wrong, inspect:
1. `routing-lib.sh` — which TIER caught it
2. Is the keyword genuinely in the right tier?
3. Is the pattern too broad? Add a more-specific TIER 1/2 rule.

Never relax TIER-1 (opus) to fix a sonnet test — that risks opus leaks.
