---
name: compare-parsers
description: Swift vs Python parser comparison harness. Haiku runs both, diffs JSON output, reports gap. No opus.
---

# /compare-parsers

**Default agent:** haiku
**Script:** `Scripts/compare_parsers.py`

## Usage

- `/compare-parsers <file>` → Compare Swift and Python parsers on the given file

## Argument

- `<file>` (required) — Any supported file format (PDF, CSV, TXT, XLSX, or other formats the parsers handle)

## Output format

```
File: <filename>
Swift:  <N> txns
Python: <M> txns
Gap:    <M-N> missing from Swift (<pct>%)
Status: PASS|GAP|REGRESS
```

## Escalation

If gap > 5% AND haiku has run this 2x in the same session → recommend the user run `/parser-refine <file>` (which involves opus).

Haiku does NOT auto-escalate. The user decides whether to pay for opus.
