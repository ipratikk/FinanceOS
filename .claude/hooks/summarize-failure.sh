#!/usr/bin/env bash
# PostToolUse hook for Bash. Detects failed builds/tests and surfaces ONE-LINE summary.
# Prevents the main thread from re-reading huge xcodebuild logs.

set -e

INPUT="$(cat)"
EXIT_CODE=$(printf '%s' "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_response',d).get('exit_code',0))" 2>/dev/null || echo 0)
CMD=$(printf '%s' "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',d).get('command',''))" 2>/dev/null || true)
OUTPUT=$(printf '%s' "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_response',d).get('output','')[:8000])" 2>/dev/null || true)

[ "$EXIT_CODE" = "0" ] && exit 0
[ -z "$CMD" ] && exit 0

# Only summarize for known commands
case "$CMD" in
  *swift\ build*|*xcodebuild*|*swift\ test*|*swift\ run*)
    ERR=$(echo "$OUTPUT" | grep -E "error:" | head -3 | tr '\n' '|')
    [ -n "$ERR" ] && printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"BUILD/TEST FAIL: %s"}}\n' "$(echo "$ERR" | sed 's/"/\\"/g')"
    ;;
  *swiftlint*)
    COUNT=$(echo "$OUTPUT" | grep -cE "warning:|error:" || echo 0)
    [ "$COUNT" -gt 0 ] && printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"swiftlint: %s violations. Run /lint fix."}}\n' "$COUNT"
    ;;
esac

exit 0
