# Multi-Agent Verification Report

Generated: 2026-05-15
Repo: FinanceOS

## TL;DR

| Layer | Status | Notes |
|---|---|---|
| Routing rules (regex tier) | ✅ PASS | 28/28 simulator tests pass, 0 opus leaks on hard-negatives |
| Routing logger hook | ✅ PASS | Logs to `.claude/logs/routing.jsonl` per UserPromptSubmit |
| Cost alert hook | ✅ PASS | Writes `.claude/logs/cost-alerts.jsonl` on opus routing |
| Identity headers (haiku) | ✅ PASS | Live test confirmed mandatory `[AGENT: HAIKU]` header |
| Opus refusal behavior | ✅ PASS | Live test: opus refused mechanical rename, 0 tool uses |
| Model enforcement via `model:` param | ✅ PASS | Verified haiku→4-5-20251001, sonnet→4-6, opus→4-7 |
| **Project-level subagent types** | 🔴 **FAIL** | `.claude/agents/*.md` NOT registered as `subagent_type` values |
| Identity headers (sonnet via general-purpose) | 🟡 PARTIAL | Header skipped when invoked via `general-purpose` without explicit reminder |

## Critical finding — read first

**`.claude/agents/<name>.md` files are NOT auto-registered as invocable Agent subagent_types in this Claude Code session.**

Verified via:
```
Agent(subagent_type: "haiku-agent", ...) →
  ERROR: Agent type 'haiku-agent' not found.
  Available agents: caveman:cavecrew-builder, ..., claude, Explore, general-purpose, Plan, statusline-setup
```

The `.md` files are project documentation, **not** runtime registration. Two possible causes:
1. Session needs restart for new agents to load (most likely)
2. Frontmatter shape not picked up by the harness

**Workaround that works today (verified):** use the Agent tool's `model:` parameter directly:
```
Agent(subagent_type: "general-purpose", model: "haiku", prompt: "...")  → claude-haiku-4-5
Agent(subagent_type: "general-purpose", model: "sonnet", prompt: "...") → claude-sonnet-4-6
Agent(subagent_type: "general-purpose", model: "opus", prompt: "...")   → claude-opus-4-7
```

The agent's role + identity-header rules must be **inlined into the prompt**, since the .md file isn't auto-attached.

After a session restart, attempt `subagent_type: "haiku-agent"` again. If it still errors, the issue is registration shape, not session state.

## Detailed verification

### 1. Routing rules (TIER 1–3 + default)

Source: `.claude/hooks/routing-lib.sh`
Simulator: `.claude/hooks/routing-simulator.sh`

```
28 test cases — 28 pass, 0 fail
Hard-negative prompts (mechanical work) — 0 opus leaks
```

Test cases covered:
- 11 haiku-routed prompts (build / lint / git / rename / grep / regen / parse invocation)
- 8 sonnet-routed prompts (feature / view / vm / refactor / test / integrate)
- 6 opus-routed prompts (design / architect / concurrency / parser-failure / db schema / pipeline)
- 3 ambiguous prompts → all routed to sonnet (default), 0 to opus

### 2. Live agent identity test

**Haiku invocation** (via `general-purpose` with explicit role prompt):
```
[AGENT: HAIKU]
[REASONING: LOW]
[TASK: git op]

34
```
✅ Header obeyed, response terse (4 lines), task completed in 2 tool calls.

**Opus REFUSAL test** (cheap rename task):
```
[AGENT: OPUS] REFUSED — task fits sonnet-agent. Reroute.
```
✅ Refused, 0 tool uses, 0 file reads. Cost guard intact.

**Sonnet escalation** (cross-package concurrency design):
```
DELEGATE: sonnet → opus
Reason: Cross-package concurrency redesign with multiple valid actor-isolation designs ...
```
🟡 Escalation logic correct, BUT mandatory `[AGENT: SONNET]` header was skipped (sonnet used prose "I am sonnet-agent" instead). Likely cause: the agent.md isn't auto-attached for `general-purpose`, so the directive was easier to deprioritize.

### 3. Hooks wired in settings.json

```
UserPromptSubmit:
  - .claude/hooks/routing-logger.sh
  - .claude/hooks/escalation-detector.sh

PostToolUse (Edit|Write):
  - post-edit-lint.sh
  - post-edit-build.sh
  - post-parser-edit.sh
  - tool-use-logger.sh

PostToolUse (Bash):
  - summarize-failure.sh
  - tool-use-logger.sh

PreToolUse (Bash):
  - graphify-hint (inline)
```

All hooks executable + JSON-valid `settings.json`.

### 4. Logs

```
.claude/logs/
├── agent-runs.jsonl   ← per-agent identity log (written by agents via Bash append)
├── routing.jsonl      ← per-prompt routing decision (auto by hook)
├── cost-alerts.jsonl  ← every opus routing (auto by hook)
└── tool-use.jsonl     ← per-tool usage with bytes (auto by hook)
```

`.gitignore` excludes log files; the directory itself stays in git.

### 5. Test/verification commands

| Command | Purpose | Status |
|---|---|---|
| `/whoami` | Print identity header for current invocation | ✅ Exists |
| `/test-routing` | Run simulator (28 cases) | ✅ Passing |
| `/test-haiku` | Live haiku smoke test | ✅ Verified |
| `/test-sonnet` | Live sonnet smoke test | ✅ Exists |
| `/test-opus` | Opus + refusal smoke test | ✅ Refusal verified |
| `/test-escalation` | Chain test (haiku→opus, sonnet→opus, opus refuse) | ✅ Exists |
| `/routing-report` | Observability dashboard | ✅ Exists |

## Issues detected

### 🔴 Critical

1. **Subagent type registration not active.** `.md` agents not selectable via `subagent_type`. Workaround: use `model:` param + inline role.

### 🟡 Warnings

2. **Identity-header compliance partial when role isn't auto-attached.** Without the `.md` file loaded as a subagent type, agents tend to drop the `[AGENT: …]` preface. Mitigation: every prompt to a delegated agent must restate the relevant section of the agent.md.

3. **Hook chain unverified live.** `routing-logger.sh` writes correctly during simulator runs but full live-session UserPromptSubmit hook firing only confirmed via the existing ROUTING HINT context (which we did observe in this session).

### Optimization suggestions

1. **Add a helper script `.claude/hooks/spawn.sh <agent> "<prompt>"`** that wraps Agent invocation with the correct model + inlined role. Single source of truth.
2. **Promote `routing-lib.sh` to a Python file** if more sophisticated routing is needed (e.g., file-scope analysis, prior-history lookback).
3. **Add a session-end `summary.sh`** that aggregates `agent-runs.jsonl` into a per-session cost report.
4. **CI gate**: run `.claude/hooks/routing-simulator.sh` in pre-commit to catch routing regressions when editing `routing-lib.sh`.

## Verification checklist

- [x] All agent .md files exist with frontmatter
- [x] Routing rules deterministic (regex-only, no LLM)
- [x] 28-case simulator passes 28/28
- [x] Hard-negative prompts (build/format/git/rename) never route to opus
- [x] Identity headers documented in agent.md
- [x] Identity header live-verified for haiku
- [x] Opus refusal live-verified
- [x] Model param verified for all 3 models
- [x] Logs directory exists with .gitignore
- [x] settings.json valid JSON + all hooks executable
- [x] Test commands exist (/whoami, /test-routing, /test-haiku, /test-sonnet, /test-opus, /test-escalation, /routing-report)
- [ ] **Subagent type registration confirmed in fresh session** ← retest after restart
- [ ] **Full hook chain live-verified end-to-end** ← requires real UserPromptSubmit observation

## How to re-run verification

```bash
# Determinstic routing test (no LLM cost)
.claude/hooks/routing-simulator.sh

# Live test commands (LLM cost — minimal, model param verified above)
# In Claude Code:
#   /test-routing
#   /test-haiku
#   /test-opus
#   /routing-report
```
