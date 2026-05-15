---
description: Run parser CLI on every PDF in Scripts/fixtures/, compare against committed golden output, report regressions. Haiku.
allowed-tools: Bash, Read
argument-hint: [bank-filter]
---

# /regression-check

Scans all parser fixtures, flags any that drifted.

## Run

```bash
.claude/hooks/regression-check.sh "${1:-}"
```

## Output

```
=== Parser Regression Report ===
✓ hdfc_apr2025.pdf  — 91 txns (no change)
✓ hdfc_may2025.pdf  — 88 txns (no change)
✗ icici_jun2025.pdf — 42 → 38 txns  (REGRESS: 4 missing)
✓ amex_jul2025.pdf  — 33 txns (no change)

Total: 4/5 pass, 1 regress
```

## Escalation

If ANY regression → recommend `/parser-debug <regressed-file>` (opus-driven).

Never silently re-baseline. Regressions require human ack.
