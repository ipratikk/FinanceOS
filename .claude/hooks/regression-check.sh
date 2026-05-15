#!/usr/bin/env bash
# Standalone regression check script invoked by /regression-check command.
# Iterates parser fixtures, compares against baseline.

set -e

cd "$(git rev-parse --show-toplevel)"

FILTER="${1:-}"

FIXTURES=$(ls Packages/FinanceParsers/Tests/Fixtures/*.pdf Packages/FinanceParsers/Tests/Fixtures/*.csv 2>/dev/null || true)

if [ -z "$FIXTURES" ]; then
  echo "No fixtures found in Packages/FinanceParsers/Tests/Fixtures/"
  exit 0
fi

PASS=0
FAIL=0
echo "=== Parser Regression Report ==="
for FIX in $FIXTURES; do
  NAME=$(basename "$FIX")
  if [ -n "$FILTER" ] && [[ "$NAME" != *"$FILTER"* ]]; then
    continue
  fi

  COUNT=$(swift run -c release --package-path Packages/FinanceParsers \
    FinanceParserCLI parse "$FIX" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('transactions',[])))" 2>/dev/null || echo "ERR")

  BASE_FILE=".claude/.parser_baseline_$NAME"
  if [ -f "$BASE_FILE" ]; then
    BASE=$(cat "$BASE_FILE")
    if [ "$COUNT" = "$BASE" ]; then
      echo "✓ $NAME — $COUNT txns (no change)"
      PASS=$((PASS+1))
    else
      echo "✗ $NAME — $BASE → $COUNT txns (REGRESS)"
      FAIL=$((FAIL+1))
    fi
  else
    echo "⊙ $NAME — $COUNT txns (no baseline, establishing)"
    echo "$COUNT" > "$BASE_FILE"
    PASS=$((PASS+1))
  fi
done

echo
echo "Total: $PASS pass, $FAIL regress"
[ "$FAIL" -gt 0 ] && exit 1 || exit 0
