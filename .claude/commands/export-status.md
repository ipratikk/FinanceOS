---
description: Export session status and token usage summary to .claude/session-status.md
allowed-tools: Bash
---

# /export-status

Manual export of session progress to `.claude/session-status.md` (gitignored).

Used when approaching token budget (~90%, 180k/200k) or at natural session boundaries.

## Run

```bash
.claude/hooks/export-status.sh
```

## Output

Updates `.claude/session-status.md` with:
- Current timestamp
- Token usage snapshot
- Completed features
- Active work
- Future scope
- Known issues + resolutions

File lives in `.gitignore` so it's session-local, not committed.

## When to Export

1. **Before context compaction** (~90% token usage)
2. **After completing major feature** (parser, framework, domain)
3. **Before handing off to next session** (full summary)
4. **Periodically** (every 30-60 min on long sessions)

## Viewing Status

```bash
cat .claude/session-status.md
```

Or read in Claude Code: `Read .claude/session-status.md`

## Auto-Export Setup (optional)

To periodically export (every 45 min):

```bash
# In Claude Code, run:
# /schedule export-status every 45 minutes
```

Currently: **manual only**. Run `/export-status` when needed.
