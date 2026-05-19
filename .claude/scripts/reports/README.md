# scripts/reports/

Report generation scripts. Read logs, produce human-readable summaries.

## Scripts

- `routing-report.py` — full routing observability dashboard. Reads logs/, prints agent stats, cost alerts, timeline, health checks.

## Output contract

Plain text, designed for terminal. Sections delimited by `=== ===`.

Health checks always last:
- opus ratio (warn >15%, critical >30%)
- hard-rule simulator result
- recent cost alerts
