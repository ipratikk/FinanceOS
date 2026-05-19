# Scriptification Report

Generated: 2026-05-16

## Summary

Converted 4 high-prose SKILL.md files to script-backed routing stubs.
Created 4 new shell scripts. Slimmed 5 files.

---

## Phase 2: Infrastructure

### New directory

- `.claude/scripts/build/` — created (was missing)
  - `README.md` — documents build.sh, exit codes, escalation

### Existing directories confirmed

- `.claude/scripts/validation/` — had README only
- `.claude/scripts/parser/` — had README only
- `.claude/scripts/session/` — had README only

---

## Phase 3: Script Conversions

### 1. snapshot-update

| Item | Before | After |
|------|--------|-------|
| SKILL.md lines | ~55 | 17 |
| Inline bash blocks | 5 (in SKILL.md) | 0 |
| Script | none | `scripts/validation/snapshot-update.sh` |
| Script lines | — | 96 |

Eliminated prose: workflow narrative, token rules, escalation rationale.
Logic moved to script: before/after capture, diff, count delta %, field key comparison, exit code signaling.

---

### 2. parser-test

| Item | Before | After |
|------|--------|-------|
| SKILL.md lines | ~50 | 22 |
| Inline bash blocks | 3 (in SKILL.md) | 0 |
| Script | none | `scripts/parser/parser-test.sh` |
| Script lines | — | 69 |

Eliminated prose: "Standard commands" section, token rules, output contract repetition.
Logic moved to script: CLI invocation, JSON summarization (python3 inline), compare dispatch.

---

### 3. commit

| Item | Before | After |
|------|--------|-------|
| SKILL.md lines | ~140 | 27 |
| Inline bash blocks | 6 (in SKILL.md) | 0 |
| Script | none | `scripts/session/commit.sh` |
| Script lines | — | 83 |

Eliminated prose: grouping heuristics essay, architecture awareness section, refactor rules,
safety rules, response format section.
Logic moved to script: layer-ordered grouping, caveman-commit invocation, dry-run mode, staged-tracking array.

---

### 4. build (project skill)

| Item | Before | After |
|------|--------|-------|
| SKILL.md lines | ~38 | 22 |
| Inline bash blocks | 1 (in SKILL.md) | 0 |
| Script | none | `scripts/build/build.sh` |
| Script lines | — | 70 |

Eliminated prose: execution block, implementation notes, scheme names repeated in prose.
Logic moved to script: target dispatch, timing, grep-filtered output, clean sequence.

---

## Token Estimates

| Skill | Before (tokens ~) | After (tokens ~) | Saved |
|-------|-------------------|------------------|-------|
| snapshot-update | ~400 | ~120 | ~280 |
| parser-test | ~350 | ~160 | ~190 |
| commit | ~900 | ~200 | ~700 |
| build (project) | ~280 | ~160 | ~120 |
| **Total** | **~1930** | **~640** | **~1290** |

Estimate basis: ~4 chars/token, measured line counts × average line length.

---

## Remaining Reasoning Workflows (stay in SKILL.md)

These remain as prose because they require LLM judgment, not scripting:

- `lint/SKILL.md` — swiftlint interpretation + fix strategy
- `parser-debug/SKILL.md` — root cause analysis for parser failures
- `refactor/SKILL.md` — architectural refactor planning
- `review/SKILL.md` — code review reasoning

---

## Files Touched

### Created

- `.claude/scripts/build/README.md`
- `.claude/scripts/build/build.sh`
- `.claude/scripts/validation/snapshot-update.sh`
- `.claude/scripts/parser/parser-test.sh`
- `.claude/scripts/session/commit.sh`
- `.claude/reports/scriptification-report.md`

### Modified (slimmed)

- `.claude/skills/snapshot-update/SKILL.md`
- `.claude/skills/parser-test/SKILL.md`
- `.claude/skills/commit/SKILL.md`
- `.claude/skills/build/SKILL.md`
- `.claude/scripts/parser/README.md`
- `.claude/scripts/session/README.md`
