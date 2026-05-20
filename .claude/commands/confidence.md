---
description: Score parser confidence on a PDF. Flags ambiguous rows, low-quality narrations, balance mismatches. Haiku runs, opus only reviews flagged items.
allowed-tools: Bash, Read, Agent
argument-hint: <pdf-path>
---

# /confidence

Parser confidence audit. Surfaces what's UNCERTAIN — not just what's wrong.

## Run

> **Note:** `Scripts/parser_confidence.py` does not yet exist. Use the inline fallback below until it is created.

```bash
swift run -c release --package-path Packages/FinanceParsers \
  FinanceParserCLI parse "$1" 2>/dev/null \
  | python3 -c "
import json, sys
txns = json.load(sys.stdin).get('transactions', [])
def score(t):
    narr = (t.get('narration') or '').strip()
    if not narr or (not t.get('debitAmount') and not t.get('creditAmount')):
        return 'LOW'
    if len(narr) < 10:
        return 'MED'
    return 'HIGH'
buckets = {'HIGH': [], 'MED': [], 'LOW': []}
for t in txns:
    buckets[score(t)].append(t)
total = max(len(txns), 1)
for tier in ('HIGH', 'MED', 'LOW'):
    n = len(buckets[tier])
    print(f'{tier}: {n} ({100*n//total}%)')
if buckets['LOW']:
    print('Low-confidence sample:')
    for t in buckets['LOW'][:5]:
        print(' ', t)
"
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
