---
description: Print the current agent's identity header. Verifies the multi-agent system is responding under the expected model.
allowed-tools: Bash
---

# /whoami

Identity probe. Each agent MUST respond with its mandatory identity header (see agents/*.md).

## Expected output

If invoked under haiku-agent:
```
[AGENT: HAIKU]
[REASONING: LOW]
[TASK: routing verification]
```

If invoked under sonnet-agent:
```
[AGENT: SONNET]
[REASONING: MEDIUM]
[TASK: routing verification]
```

If invoked under opus-agent:
```
[AGENT: OPUS]
[REASONING: HIGH]
[TASK: routing verification]

⚠️ OPUS WARNING
Reason: <should explain>
```

If the response is missing the header → agent is not loading its `.claude/agents/<name>.md` directive. **FAIL**.

## Also report

```bash
echo "settings.json hooks active:"
python3 -c "import json; d=json.load(open('.claude/settings.json')); print(json.dumps({k:[h['command'] for entry in v for h in entry.get('hooks',[])] for k,v in d.get('hooks',{}).items()},indent=2))"
```
