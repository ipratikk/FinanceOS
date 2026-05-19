---
name: snapshot-update
description: Regenerate test fixtures/golden JSON. Haiku-only. Escalates to opus on unexpected structural delta.
---

# /snapshot-update

**Default agent:** haiku
**Script:** `.claude/scripts/validation/snapshot-update.sh`

## Variants

- `/snapshot-update parser hdfc` → `snapshot-update.sh hdfc`
- `/snapshot-update graph` → `snapshot-update.sh graph`
- `/snapshot-update all` → `snapshot-update.sh all`

## Escalation

Script exits 2 → escalate to opus. Exit 0/1 → haiku commits.

## Escalation triggers (from script)

- txn count drops > 5%
- field added or removed in any record
- sign flipped on any amount
