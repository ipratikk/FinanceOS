#!/usr/bin/env bash
# Triggered after Edit/Write on .swift files.
# Quick build of the affected package only. Failures surface as additional context.
# Designed to be cheap: only builds the package containing the edited file.

set -e

# Read tool input from stdin
INPUT="$(cat)"
FILE=$(printf '%s' "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',d).get('file_path',''))" 2>/dev/null || true)

[ -z "$FILE" ] && exit 0
[[ ! "$FILE" =~ \.swift$ ]] && exit 0

# Identify target package by path
PKG=""
case "$FILE" in
  */Packages/FinanceCore/*)    PKG="Packages/FinanceCore" ;;
  */Packages/FinanceParsers/*) PKG="Packages/FinanceParsers" ;;
  *)                           exit 0 ;;  # skip non-package files (app builds are slower)
esac

cd "$(git rev-parse --show-toplevel)" || exit 0

# Skip if a build is already in-flight (lockfile)
LOCK="/tmp/financeos_build_${PKG//\//_}.lock"
if [ -f "$LOCK" ]; then
  # If lock is older than 60s, kill it (stale)
  if [ "$(($(date +%s) - $(stat -f %m "$LOCK" 2>/dev/null || echo 0)))" -gt 60 ]; then
    rm -f "$LOCK"
  else
    exit 0
  fi
fi
touch "$LOCK"
trap 'rm -f "$LOCK"' EXIT

# Cheap incremental build, capture only errors
OUTPUT=$(swift build --package-path "$PKG" 2>&1 | grep -E "error:|warning:" | head -10)

if echo "$OUTPUT" | grep -q "error:"; then
  ERRS=$(echo "$OUTPUT" | grep "error:" | head -5)
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"BUILD FAIL after edit to %s:\\n%s\\n→ delegate to haiku-agent to fix, escalate to sonnet if cross-file."}}\n' \
    "$FILE" "$(echo "$ERRS" | sed 's/"/\\"/g' | tr '\n' '|')"
fi

exit 0
