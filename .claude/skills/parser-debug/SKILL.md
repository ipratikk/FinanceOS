---
name: parser-debug
description: Investigate parser failures with structured hypothesis testing. Opus plans, haiku probes. Use for "parser gives wrong output" / "missing transactions" / "narration garbled" scenarios.
---

# /parser-debug

Root-cause parser bugs without dumping the whole codebase into context.

## Default agent

**opus-agent** for the hypothesis. **haiku-agent** for the probing. **sonnet-agent** for implementing the fix once opus has a plan.

This is one of the few skills where opus is appropriate by default — parser bugs are inherently cross-component reasoning.

## Workflow (recursive)

```
opus  → hypothesis #1: "PDFKit returns column-major text on this PDF"
haiku → probe: dump first 50 lines of PDFKit page.string, report Y-coordinate spread of char 100
opus  → revised hypothesis given new data
haiku → probe again
...
opus  → final plan: "switch to Vision OCR"
sonnet→ implement the plan
haiku → run /parser-test, report delta
```

## Hard rules

- opus NEVER edits parser code directly. opus writes a one-line probe, haiku runs it.
- max 3 probe rounds before opus must produce a written plan.
- if opus cannot form a hypothesis after 3 probes → write a "this needs human input" note and STOP.

## Probe templates haiku can run

```bash
# Dump raw PDFKit text from page N
swift Scripts/debug_pdfkit.swift <pdf>

# Compare Swift vs Python output
python3 Scripts/compare_parsers.py <pdf>

# Show only missing transactions
diff <(swift_out) <(python_out) | head -30

# Test single date format
swift Scripts/test_date_parse.swift "<date>"
```

## Escalation matrix

| Symptom | First agent | If unsolved |
|---|---|---|
| Wrong txn count | opus (1 probe budget) | hand to user |
| Wrong amount sign | sonnet | opus |
| Missing narrations | opus | hand to user |
| Date parse failure | haiku (try known formats) | sonnet |
| Crash | sonnet (read stack) | opus if concurrency |

## Output contract

Opus produces:
```
## Hypothesis
<one sentence>

## Probe
<command for haiku to run>

## Decision criterion
<what result confirms vs refutes the hypothesis>
```

After 3 rounds, opus produces a final Plan (see opus-agent.md).
