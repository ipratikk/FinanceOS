---
name: review
description: Diff/file/PR review. One line per finding, severity-tagged. Default agent haiku (mechanical pattern-matching). Escalates to sonnet for architectural review, opus for design review.
---

# /review

Surgical review. No praise. No scope creep.

## Default agent

**haiku-agent** for diff review (style, obvious bugs, missing tests).
**sonnet-agent** for architectural review (does this belong here? abstraction shape?).
**opus-agent** only for design review of a NEW pipeline or NEW system boundary.

## Variants

- `/review` → current branch diff vs main
- `/review file <path>` → single file audit
- `/review pr <num>` → GitHub PR (via gh)
- `/review arch` → cross-module architectural pass (sonnet)
- `/review design <doc>` → design doc critique (opus)

## Output format

One line per finding:
```
path:line: <emoji> <severity>: <problem>. <fix>.
```

Severities:
- 🔴 BLOCKER — correctness, security, data loss
- 🟠 HIGH — perf regression, missing error handling, API contract break
- 🟡 MED — design smell, missing test
- ⚪ LOW — style only (suppress unless asked)

## Forbidden

- multi-paragraph commentary
- "looks good!" / praise
- restating what the code does
- formatting nits unless they change meaning

## Token rules

- read only the diff, not surrounding context unless a finding requires it
- never paste code blocks > 5 lines in findings
- group findings by file, sort by severity desc
- skip LOW unless `--strict` requested
