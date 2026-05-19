---
description: Validate parser output against expected JSON fixture. Haiku.
allowed-tools: Bash, Read
argument-hint: <pdf-or-csv-path> <expected-json>
---

# /fixture-validate

Pure JSON comparison. No reasoning.

## Run

```bash
swift run -c release --package-path Packages/FinanceParsers \
  FinanceParserCLI parse "$1" 2>/dev/null > /tmp/actual.json

diff <(jq -S .transactions /tmp/actual.json) <(jq -S .transactions "$2") | head -40
```

## Output

```
expected: <N> txns
actual:   <M> txns
match:    <count> exact, <count> partial, <count> missing
status:   PASS|FAIL
```

PASS = 100% exact match. Anything else = FAIL.

## Escalation

FAIL → user decides whether to /parser-debug or /snapshot-update.
