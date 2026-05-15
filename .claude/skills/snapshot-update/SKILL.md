---
name: snapshot-update
description: Regenerate test fixtures, golden JSON snapshots, parser reference outputs. Haiku-only. Diffs before/after, escalates only on unexpected delta.
---

# /snapshot-update

Refresh fixtures. Never blindly. Haiku does, opus only sees diffs > threshold.

## Default agent

**haiku-agent** for the regeneration + the diff.
**opus-agent** consulted ONLY if the diff is structurally unexpected (e.g., field added, sign flipped, txn count drop > 5%).

## Variants

- `/snapshot-update parser hdfc` → regenerate HDFC fixture JSON
- `/snapshot-update graph` → run `graphify update .`
- `/snapshot-update all` → all fixtures

## Workflow (haiku)

```bash
# 1. Capture current fixture
cp Packages/FinanceParsers/Tests/Fixtures/hdfc_expected.json /tmp/before.json

# 2. Regenerate
swift run -c release --package-path Packages/FinanceParsers FinanceParserCLI parse <pdf> > /tmp/after.json

# 3. Diff
diff <(jq -S . /tmp/before.json) <(jq -S . /tmp/after.json) | head -50

# 4. If delta is small + expected (e.g., new test PDF added), commit.
# 5. If delta is large or structural, ESCALATE.
```

## Escalation rules

Escalate to **opus-agent** when:
- txn count changes by > 5%
- field added or removed in any record
- sign flipped on any amount
- description content changed for > 10% of records

In that case haiku writes:
```
SNAPSHOT DELTA UNEXPECTED
before: <count>, after: <count>
sample diffs:
<5 lines>
escalating to opus for review
```

## Token rules

- diff with `head -50`, never paste full JSON
- use `jq -S .` (sorted keys) to reduce noise
- prefer line-level diff over structural
