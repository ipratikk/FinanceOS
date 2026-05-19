---
description: Swift vs Python parser comparison harness. Haiku runs both, diffs JSON output, reports gap. No opus.
allowed-tools: Bash, Read, Skill
argument-hint: <pdf-path>
---

# /compare-parsers

100% haiku. Reads two JSON blobs, reports gap.

## Run

```bash
python3 Scripts/compare_parsers.py "$1"
```

Output is the canonical comparison report. Do NOT re-parse or re-analyze. Just surface the result.

## Output format

```
PDF: $1
Swift:  <N> txns | Dr <amt> | Cr <amt>
Python: <M> txns | Dr <amt> | Cr <amt>
Gap:    <M-N> missing from Swift (<pct>%)
Status: PASS|GAP|REGRESS
```

## Escalation

If gap > 5% AND haiku has run this 2x in the same session → recommend the user run `/parser-refine $1` (which involves opus).

Haiku does NOT auto-escalate. The user decides whether to pay for opus.
