# `.claude/` — FinanceOS Multi-Agent Workflow

```
.claude/
├── agents/           ← haiku / sonnet / opus model definitions
├── commands/         ← user-facing /slash workflows
├── skills/           ← reusable skill blueprints
├── hooks/            ← auto-routing + summarizers
├── settings.json     ← hook + permission wiring
├── ROUTING.md        ← model selection rules
└── README.md
```

## Quick start

| If you want to... | Run |
|---|---|
| Build the project | `/build` (haiku) |
| Run parser on PDF | `/parser-test cli <pdf>` (haiku) |
| Compare Swift vs Python | `/compare-parsers <pdf>` (haiku) |
| Check for parser regressions | `/regression-check` (haiku) |
| Debug a parser failure | `/parser-debug <pdf>` (opus + haiku probes) |
| Recursively improve parser | `/parser-refine <pdf>` (capped 5 opus cycles) |
| Confidence-score a parse | `/confidence <pdf>` (haiku) |
| Validate against fixture | `/fixture-validate <pdf> <expected.json>` (haiku) |
| Review the current diff | `/review` (haiku) |
| Refactor mechanically | `/refactor rename old new` (haiku) |
| Lint + fix | `/lint fix` (haiku) |
| Update fixtures | `/snapshot-update parser hdfc` (haiku) |
| Ask "which agent for X?" | `/route "task description"` |

## Hard cost discipline

See [ROUTING.md](ROUTING.md). Bottom line: **opus only plans, haiku executes**.

## Adding a new agent / skill / command

- Agents: `.claude/agents/<name>.md` with frontmatter `name`, `description`, `model`, `tools`
- Skills: `.claude/skills/<name>/SKILL.md` with frontmatter `name`, `description`
- Commands: `.claude/commands/<name>.md` with frontmatter `description`, `allowed-tools`, `argument-hint`
- Hooks: `.claude/hooks/<name>.sh` (executable) + wired in `settings.json`

## Hooks active

- **UserPromptSubmit** → `escalation-detector.sh`: annotates each prompt with routing hint
- **PostToolUse(Edit|Write)** → `post-edit-lint.sh` + `post-edit-build.sh` + `post-parser-edit.sh`
- **PostToolUse(Bash)** → `summarize-failure.sh`: collapses verbose build/test failures
- **PreToolUse(Bash)** → graphify hint when grepping
