# scripts/session/

Session lifecycle management scripts.

## Scripts

- `commit.sh [--dry-run]` — group unstaged changes by architecture layer, commit each via caveman-commit.
  Layers: parsers → finance-core → finance-ui → app → claude-config → scripts → tests → misc.
- `export.sh` — export current session state to .claude/session-status.md.
  Writes: timestamp, git HEAD, modified files, log summaries, agent run counts.

## When to run

- manually at natural session boundaries
- at ~90% token budget (triggered by token-monitor.sh)
- before handing off to a new session

## Output

Updates `.claude/session-status.md` (gitignored).
Prints a one-line confirmation: `exported: .claude/session-status.md (<N> lines)`
