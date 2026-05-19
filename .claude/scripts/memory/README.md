# scripts/memory/

Token budget monitoring and session memory scripts.

## Scripts

- `token-monitor.sh` — check current token usage vs budget threshold, alert at 90%.

## Inputs

Reads `.claude/session-status.md` for current token snapshot.

## Output

Single-line status:
```
✓ comfortable (42% used)
🟡 warning: 81% used
🔴 critical: 91% used — export now
```

Exit codes: 0=ok, 1=warning, 2=critical.
