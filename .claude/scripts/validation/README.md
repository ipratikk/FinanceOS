# scripts/validation/

Parser correctness validation scripts. All deterministic — no LLM.

## Scripts

- `regression-check.sh [bank-filter]` — run parser CLI on every fixture, compare to baseline. Exit 1 on any regress.
- `fixture-validate.sh <pdf-or-csv> <expected-json>` — diff actual vs expected JSON. Exit 1 on mismatch.
- `snapshot-update.sh <bank> [all]` — regenerate fixture JSON, diff before/after, alert on unexpected delta.

## Baselines

Stored as `.claude/.parser_baseline_<fixture-name>` (gitignored).
First run on a fixture establishes the baseline. Subsequent runs compare.

## Escalation signals (exit codes)

- 0 = all pass
- 1 = regression detected (recommend /parser-debug)
- 2 = unexpected structural delta (recommend opus review)
