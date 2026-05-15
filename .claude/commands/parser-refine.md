---
description: Recursive parser refinement loop. Opus designs heuristic → haiku applies + runs tests → repeat until accuracy target hit.
allowed-tools: Read, Edit, Write, Bash, Grep, Glob, Agent, Skill
argument-hint: <pdf-path> [target-accuracy=0.95]
---

# /parser-refine

Recursive accuracy-loop for parser heuristics. Capped at 5 iterations to prevent runaway opus cost.

## Inputs

- `$1` — PDF path
- `$2` — target accuracy (default 0.95)

## Loop

```
iteration = 0
while accuracy < target AND iteration < 5:
  1. haiku: run /parser-test cli $1 → record count, totals
  2. haiku: run python3 Scripts/compare_parsers.py $1 → record expected count
  3. compute accuracy = swift_count / python_count
  4. if accuracy >= target → DONE
  5. opus: read at most 2 missing-txn diff samples, propose ONE heuristic change
  6. haiku: apply opus's diff
  7. haiku: rebuild + retest
  iteration++
```

## Hard rules

- opus is invoked AT MOST 5 times per loop
- opus produces a diff < 30 lines per iteration
- if accuracy decreases between iterations → REVERT haiku's last change + STOP
- if iteration 5 hits and accuracy < target → write `parser_refine_log.md` and STOP

## Workflow agent invocations

```
Agent(subagent_type: haiku-agent, prompt: "run /parser-test cli $1, report Txns=N Dr=X Cr=Y")
Agent(subagent_type: opus-agent,  prompt: "given delta of M missing txns in <sample>, propose ONE heuristic change to <file>. Output unified diff only.")
Agent(subagent_type: haiku-agent, prompt: "apply this diff and rerun /parser-test cli $1: <diff>")
```

## Output

```
=== /parser-refine $1 ===
iter 0: 94 / 429 → 21.9%
iter 1: 142 / 429 → 33.1%  (heuristic: column-X tolerance widening)
iter 2: 268 / 429 → 62.5%  (heuristic: narration-line dedup)
...
final: 419 / 429 → 97.7%   PASS
```

## Cost guard

If opus is invoked 5x and target not hit, the loop ends with a written failure report. Do NOT silently keep retrying.
