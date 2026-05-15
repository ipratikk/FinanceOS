---
name: parser-test
description: Run FinanceParsers tests + CLI on real PDFs/CSVs to validate output. Default agent haiku. Compares against reference fixtures.
---

# /parser-test

Validate parser correctness without burning tokens on every iteration.

## Default agent

**haiku-agent**. Test execution + JSON diff is mechanical.

## Variants

- `/parser-test` → run full test suite
- `/parser-test hdfc` → only HDFC fixtures
- `/parser-test cli <pdf>` → invoke FinanceParserCLI on a PDF, show txn count + totals
- `/parser-test compare <pdf>` → Swift vs Python reference (uses Scripts/compare_parsers.py)

## Standard commands

```bash
# Unit tests
swift test --package-path Packages/FinanceParsers 2>&1 | tail -30

# CLI invocation (haiku reports only counts + totals, NOT full JSON)
swift run -c release --package-path Packages/FinanceParsers \
  FinanceParserCLI parse "<pdf>" 2>/dev/null \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'Txns={len(d[\"transactions\"])} Dr={d[\"totalDebit\"]/100:.2f} Cr={d[\"totalCredit\"]/100:.2f}')"

# Swift vs Python
python3 Scripts/compare_parsers.py "<pdf>"
```

## Escalation triggers

- output count differs from expected by > 5% → escalate to **opus-agent** for heuristic redesign
- new unrecognized error category → escalate to **sonnet-agent**
- reference Python parser also fails → escalate to **opus-agent**

## Output contract

```
Parser: <bank>
Txns: <count> (expected <count>)
Debit:  <amt>
Credit: <amt>
Status: PASS|FAIL|REGRESS
Delta: <diff vs last run>
```

## Token rules

- NEVER paste full transaction JSON
- always summarize: count, totals, first 3 + last 3 entries
- if comparing against reference: only print MISSING entries, not matches
