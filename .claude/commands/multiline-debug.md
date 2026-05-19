---
description: Hypothesis-driven debug of multiline narration reconstruction. Opus reasons, haiku probes.
allowed-tools: Read, Bash, Agent, Skill
argument-hint: <pdf-path> [page-num=0]
---

# /multiline-debug

Drill into ONE page where reconstruction fails.

## Workflow

```
Step 1 (haiku): swift Scripts/debug_pdfkit.swift "$1" | head -80
Step 2 (haiku): swift /tmp/debug_rows.swift "$1" | head -60  (position-based extraction)
Step 3 (opus):  given outputs from Step 1+2, identify the row-grouping failure mode
Step 4 (opus):  propose ONE-LINE heuristic adjustment (tolerance, separator, etc.)
Step 5 (haiku): apply + rerun parser-test
```

## Hard rules

- max 3 hypothesis cycles
- opus reads MAX 50 lines per cycle
- if 3 cycles fail to improve accuracy → STOP, write findings to `parser_multiline_findings.md`

## Output

```
hypothesis 1: <tested via probe>
  result: <confirmed|refuted>
hypothesis 2: ...
final fix: <one-line description>
accuracy delta: <before> → <after>
```
