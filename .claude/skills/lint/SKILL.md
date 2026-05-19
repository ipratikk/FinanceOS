---
name: lint
description: Run swiftlint, fix violations. Haiku-only. Never escalates — if rule is wrong, user changes the rule, not the agent.
---

# /lint

100% haiku. No exceptions.

## Variants

- `/lint` → lint all targets, show violations summary
- `/lint fix` → swiftlint --fix + apply trivial format edits
- `/lint <path>` → lint single file

## Commands

```bash
swiftlint lint --quiet 2>&1 | tail -20
swiftlint lint --fix --quiet 2>&1 | tail -10
```

## Hard rules

- never disable a rule in source without explicit user request
- never edit .swiftlint.yml
- if a violation persists after `--fix`, report it — do NOT manually rewrite the file
- if 50+ violations: ask user before auto-fixing

## Output

```
swiftlint: <total> violations (<errors> errors, <warnings> warnings)
top 10:
  <file>:<line>: <rule> — <message>
  ...
fixed: <count>
remaining: <count>
```

## Token rules

- never paste full lint output
- always tail/grep
- summarize by rule type when count > 20
