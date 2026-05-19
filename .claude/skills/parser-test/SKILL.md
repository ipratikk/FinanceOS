---
name: parser-test
description: Run FinanceParsers tests + CLI on real files. Default agent haiku.
---

# /parser-test

**Default agent:** haiku
**Script:** `.claude/scripts/parser/parser-test.sh`

## Variants

- `/parser-test` → `parser-test.sh`
- `/parser-test hdfc` → `parser-test.sh hdfc`
- `/parser-test cli <file>` → `parser-test.sh cli <file>`
- `/parser-test compare <file>` → `parser-test.sh compare <file>`

## Output contract

```
Parser: <bank>
Txns: <count> (expected <count>)
Debit:  <amt>
Credit: <amt>
Status: PASS|FAIL|REGRESS
```

## Escalation

- count differs > 5% → opus
- new unrecognized error category → sonnet
- Python reference also fails → opus
