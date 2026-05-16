# scripts/parser/

Parser validation and comparison scripts. All deterministic — no LLM.

## Scripts

- `parser-test.sh [mode] [args]` — unified entry point for all parser testing (see /parser-test skill).
  Modes: `(none)` = full suite, `<bank>` = filtered, `cli <file>` = CLI smoke, `compare <file>` = Swift vs Python.
- `compare.sh <pdf>` — Swift vs Python comparison. Exits 0 on match, 1 on gap.
- `confidence.py <pdf>` — Per-transaction confidence scoring (HIGH/MED/LOW).
- `debug.py <pdf>` — Structured parser debug: dump raw text, column positions, row groups.
- `test.sh [bank-filter]` — Run FinanceParsers test suite + CLI smoke test (legacy; prefer parser-test.sh).

## Output contract

All scripts print machine-readable output:
- counts and totals on one line
- status: PASS|FAIL|GAP|REGRESS on last line
- exit code: 0=pass, 1=fail/gap

## Parser CLI path

`swift run -c release --package-path Packages/FinanceParsers FinanceParserCLI parse <file>`
