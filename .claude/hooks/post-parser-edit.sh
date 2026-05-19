#!/usr/bin/env bash
# Triggered after Edit/Write on parser source files.
# Auto-runs parser CLI on a known-good fixture if one exists, reports delta.
# This is haiku-cheap, intended to catch regressions immediately.

set -e

INPUT="$(cat)"
FILE=$(printf '%s' "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',d).get('file_path',''))" 2>/dev/null || true)

[ -z "$FILE" ] && exit 0
# Only trigger on parser files
[[ ! "$FILE" =~ FinanceParsers/.*\.swift$ ]] && exit 0

cd "$(git rev-parse --show-toplevel)" || exit 0

# Use first available regression fixture
FIXTURE=$(ls Packages/FinanceParsers/Tests/Fixtures/*.pdf 2>/dev/null | head -1)
[ -z "$FIXTURE" ] && exit 0

# Skip if a parser-test is already in-flight
LOCK="/tmp/financeos_parser_test.lock"
if [ -f "$LOCK" ]; then
  if [ "$(($(date +%s) - $(stat -f %m "$LOCK" 2>/dev/null || echo 0)))" -gt 120 ]; then
    rm -f "$LOCK"
  else
    exit 0
  fi
fi
touch "$LOCK"
trap 'rm -f "$LOCK"' EXIT

# Run parser, capture only count
COUNT=$(swift run -c release --package-path Packages/FinanceParsers \
  FinanceParserCLI parse "$FIXTURE" 2>/dev/null \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('transactions',[])))" 2>/dev/null || echo "ERR")

# Compare to stored baseline
BASELINE_FILE=".claude/.parser_baseline_$(basename "$FIXTURE")"
if [ -f "$BASELINE_FILE" ]; then
  BASELINE=$(cat "$BASELINE_FILE")
  if [ "$COUNT" != "$BASELINE" ] && [ "$COUNT" != "ERR" ]; then
    printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"PARSER DRIFT: %s now produces %s txns (baseline: %s). Run /parser-test or /parser-debug to investigate."}}\n' \
      "$(basename "$FIXTURE")" "$COUNT" "$BASELINE"
  fi
else
  # First run — establish baseline
  echo "$COUNT" > "$BASELINE_FILE"
fi

exit 0
