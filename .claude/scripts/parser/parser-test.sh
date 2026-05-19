#!/usr/bin/env bash
# parser-test.sh [mode] [args...]
#
# Modes:
#   (none)          — run full FinanceParsers test suite
#   <bank>          — run suite, filter output to bank name
#   cli <file>      — invoke CLI on file, print txn count + totals only
#   compare <file>  — run Swift CLI vs Python reference parser
#
# Exit codes:
#   0 = PASS
#   1 = FAIL / REGRESS
#   2 = unexpected delta (escalate to opus)

set -euo pipefail

REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
PARSERS_PKG="$REPO_ROOT/Packages/FinanceParsers"
SCRIPTS_DIR="$REPO_ROOT/Scripts"

MODE="${1:-}"
ARG="${2:-}"

run_suite() {
  local filter="${1:-}"
  echo "Running FinanceParsers tests..."
  if [ -n "$filter" ]; then
    swift test --package-path "$PARSERS_PKG" 2>&1 \
      | grep -iE "(error:|warning:|PASS|FAIL|${filter})" \
      | tail -50
  else
    swift test --package-path "$PARSERS_PKG" 2>&1 | tail -30
  fi
}

run_cli() {
  local file="$1"
  [ -f "$file" ] || { echo "ERROR: file not found: $file" >&2; exit 1; }
  echo "Parser CLI: $(basename "$file")"
  swift run -c release --package-path "$PARSERS_PKG" \
    FinanceParserCLI parse "$file" 2>/dev/null \
    | python3 -c "
import sys, json
d = json.load(sys.stdin)
stmt = d.get('statement', d)
txns = stmt.get('transactions', [])
total_dr = sum(t.get('amountMinorUnits', 0) for t in txns if t.get('amountMinorUnits', 0) > 0)
total_cr = sum(abs(t.get('amountMinorUnits', 0)) for t in txns if t.get('amountMinorUnits', 0) < 0)
print(f'Txns={len(txns)} Dr={total_dr/100:.2f} Cr={total_cr/100:.2f}')
if txns:
    print('First 3:')
    for t in txns[:3]:
        fp = t.get('sourceFingerprint', '')
        date = fp.split('|')[0] if fp else '?'
        print(f\"  {date} {t.get('description','?')[:40]}\")
    if len(txns) > 3:
        print('Last 3:')
        for t in txns[-3:]:
            fp = t.get('sourceFingerprint', '')
            date = fp.split('|')[0] if fp else '?'
            print(f\"  {date} {t.get('description','?')[:40]}\")
"
}

run_compare() {
  local file="$1"
  [ -f "$file" ] || { echo "ERROR: file not found: $file" >&2; exit 1; }
  local py_script="$SCRIPTS_DIR/compare_parsers.py"
  if [ ! -f "$py_script" ]; then
    echo "WARNING: compare_parsers.py not found at $py_script" >&2
    echo "Running CLI only..."
    run_cli "$file"
    exit 0
  fi
  python3 "$py_script" "$file"
}

case "$MODE" in
  "")
    run_suite
    ;;
  cli)
    [ -n "$ARG" ] || { echo "Usage: parser-test.sh cli <file>" >&2; exit 1; }
    run_cli "$ARG"
    ;;
  compare)
    [ -n "$ARG" ] || { echo "Usage: parser-test.sh compare <file>" >&2; exit 1; }
    run_compare "$ARG"
    ;;
  *)
    # Bank filter
    run_suite "$MODE"
    ;;
esac
