# scripts/agents/

Agent orchestration helpers. Not LLM scripts — scaffolding only.

## Scripts

- `spawn.sh <haiku|sonnet|opus> "<task>"` — print a ready-to-paste Agent({}) invocation.
- `log-run.sh <agent> <task> <files...>` — append one line to .claude/logs/agent-runs.jsonl.

## Usage

```bash
.claude/scripts/agents/spawn.sh haiku "run swift build and report errors"
.claude/scripts/agents/log-run.sh sonnet "feature implementation" "Foo.swift" "Bar.swift"
```

## Invariants

- spawn.sh prints to stdout only. Never executes anything.
- log-run.sh appends exactly one JSONL line. Never reads existing logs.
