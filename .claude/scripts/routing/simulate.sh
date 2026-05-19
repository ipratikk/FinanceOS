#!/usr/bin/env bash
# simulate.sh — run all canned prompts through routing lib, report PASS/FAIL.
# Exit 0: all pass + no opus leaks. Exit 1: any failure.

set -e
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"

declare -a CASES=(
  # haiku
  "format this file|haiku"
  "rebuild the project|haiku"
  "swift build the package|haiku"
  "run parser tests|haiku"
  "swiftlint fix|haiku"
  "fix typo in HDFCPDFParser comment|haiku"
  "commit these changes|haiku"
  "rename foo to bar|haiku"
  "grep for ParsedTransaction|haiku"
  "regenerate the hdfc fixture|haiku"
  "parse the PDF and report counts|haiku"

  # sonnet
  "add a new SwiftUI screen for transaction tags|sonnet"
  "build a settings view|sonnet"
  "implement TXTStatementParser|sonnet"
  "write unit tests for HDFCMetadataExtractor|sonnet"
  "refactor the dedup helper|sonnet"
  "wire up the new repository method|sonnet"
  "integrate the import view with the parser|sonnet"
  "build SwiftUI dashboard|sonnet"

  # opus
  "design the parser pipeline for multi-bank ingestion|opus"
  "architect the dedup engine for multi-currency|opus"
  "fix concurrency issue in ingestion|opus"
  "the parser is broken and missing transactions|opus"
  "design the database schema for budgets|opus"
  "redesign concurrency layer|opus"

  # ambiguous — must land at sonnet
  "improve the codebase|sonnet"
  "make it faster|sonnet"
  "look into this bug|sonnet"
)

PASS=0; FAIL=0; FAILS=""
printf "%-60s %-8s %-8s %s\n" "PROMPT" "EXPECT" "ACTUAL" "STATUS"
printf "%-60s %-8s %-8s %s\n" "------" "------" "------" "------"

for case in "${CASES[@]}"; do
  prompt="${case%|*}"
  expected="${case#*|}"
  result=$(route_prompt "$prompt")
  actual=$(echo "$result" | grep "^AGENT=" | cut -d= -f2)
  reason=$(echo "$result" | grep "^REASON=" | cut -d= -f2-)
  if [ "$actual" = "$expected" ]; then
    status="PASS"; PASS=$((PASS+1))
  else
    status="FAIL"; FAIL=$((FAIL+1))
    FAILS="${FAILS}  - \"$prompt\" expected=$expected actual=$actual reason=$reason\n"
  fi
  printf "%-60s %-8s %-8s %s\n" "${prompt:0:58}" "$expected" "$actual" "$status"
done

echo
echo "Total: $PASS pass, $FAIL fail (of $((PASS+FAIL)))"
[ -n "$FAILS" ] && echo -e "\nFailures:\n$FAILS"

# Hard-rule: no opus on cheap tasks
echo
echo "── Hard-rule checks ──"
declare -a NEGATIVES=(
  "build the project"
  "format this swift file"
  "run swiftlint --fix"
  "commit the staged files"
  "rename the function"
)
LEAKS=0
for p in "${NEGATIVES[@]}"; do
  agent=$(route_prompt "$p" | grep "^AGENT=" | cut -d= -f2)
  if [ "$agent" = "opus" ]; then
    echo "CRITICAL: \"$p\" routed to opus"
    LEAKS=$((LEAKS+1))
  fi
done
[ "$LEAKS" = "0" ] && echo "no opus leaks on hard-negative prompts"

[ "$FAIL" = "0" ] && [ "$LEAKS" = "0" ] && exit 0 || exit 1
