---
description: Score parser confidence on a PDF. Flags ambiguous rows, low-quality narrations, balance mismatches. Haiku runs, opus only reviews flagged items.
allowed-tools: Bash, Read, Agent
argument-hint: <pdf-path>
---

# /confidence

Parser confidence audit. Surfaces what's UNCERTAIN — not just what's wrong.

## Run

```bash
swift run -c release --package-path Packages/FinanceParsers \
  FinanceParserCLI parse "$1" 2>/dev/null \
  | python3 Scripts/parser_confidence.py
```

## Score per transaction (haiku)

- ✅ HIGH: date parsed, narration > 10 chars, debit XOR credit set, balance reconciles
- 🟡 MED: ANY 1 weakness (e.g., narration < 10 chars OR balance off by < 100 paise)
- 🔴 LOW: missing narration, both debit AND credit zero, balance off > 100 paise

## Output

```
=== Confidence Report: $1 ===
HIGH: <N>  (<pct>%)
MED:  <N>  (<pct>%)
LOW:  <N>  (<pct>%)

Low-confidence sample:
  row 42: date=01/04/25 desc="" amount=-2500 balance_drift=128
  row 88: date=14/04/25 desc="UPI" amount=+0 balance_drift=0
```

## Escalation

If LOW > 10% → recommend `/parser-debug $1` for opus review of the LOW-tier rows ONLY.

Haiku NEVER auto-invokes opus. The user reviews the report and decides.
