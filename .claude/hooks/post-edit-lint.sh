#!/usr/bin/env bash
# Triggered after Edit/Write on .swift files. Runs swiftlint on the SINGLE file only.
# Surfaces violations as context (not blocking).

set -e

INPUT="$(cat)"
FILE=$(printf '%s' "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',d).get('file_path',''))" 2>/dev/null || true)

[ -z "$FILE" ] && exit 0
[[ ! "$FILE" =~ \.swift$ ]] && exit 0
[ ! -f "$FILE" ] && exit 0

# Skip if swiftlint not installed
command -v swiftlint >/dev/null 2>&1 || exit 0

cd "$(git rev-parse --show-toplevel)" || exit 0

VIOLATIONS=$(swiftlint lint --quiet --path "$FILE" 2>/dev/null | head -10)

if [ -n "$VIOLATIONS" ]; then
  COUNT=$(echo "$VIOLATIONS" | wc -l | tr -d ' ')
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"swiftlint: %s violations in %s. Run /lint fix to auto-fix."}}\n' \
    "$COUNT" "$(basename "$FILE")"
fi

exit 0
