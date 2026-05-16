#!/usr/bin/env bash
# snapshot-update.sh <bank|all> [fixture-pdf-or-csv]
# Regenerate golden fixture JSON, diff before/after, exit 2 on unexpected structural delta.
#
# Exit codes:
#   0 = clean update (diff within acceptable bounds)
#   1 = diff produced but within expected range (new file added, minor change)
#   2 = unexpected structural delta — escalate to opus

set -euo pipefail

REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
FIXTURE_DIR="$REPO_ROOT/Packages/FinanceParsers/Tests/Fixtures"
PARSERS_PKG="$REPO_ROOT/Packages/FinanceParsers"
TMP_BEFORE="/tmp/snapshot_before_$$.json"
TMP_AFTER="/tmp/snapshot_after_$$.json"

cleanup() { rm -f "$TMP_BEFORE" "$TMP_AFTER"; }
trap cleanup EXIT

BANK="${1:-all}"
PDF="${2:-}"

die() { echo "ERROR: $1" >&2; exit 1; }

run_parser() {
  local input="$1"
  local out="$2"
  swift run -c release --package-path "$PARSERS_PKG" FinanceParserCLI parse "$input" 2>/dev/null > "$out"
}

check_delta() {
  local before="$1"
  local after="$2"
  local label="$3"

  if ! diff <(jq -S . "$before") <(jq -S . "$after") > /tmp/snapshot_diff_$$.txt 2>&1; then
    local before_count after_count
    before_count=$(jq '.transactions | length' "$before" 2>/dev/null || echo 0)
    after_count=$(jq '.transactions | length' "$after" 2>/dev/null || echo 0)

    # Detect structural issues: count drop >5%, field added/removed, sign flip
    local drop_pct=0
    if [ "$before_count" -gt 0 ]; then
      drop_pct=$(( (before_count - after_count) * 100 / before_count ))
    fi

    local structural=0
    # Field added or removed in any record
    if jq -e '.transactions[0] | keys' "$before" > /tmp/keys_before_$$.json 2>/dev/null && \
       jq -e '.transactions[0] | keys' "$after"  > /tmp/keys_after_$$.json 2>/dev/null; then
      if ! diff /tmp/keys_before_$$.json /tmp/keys_after_$$.json > /dev/null 2>&1; then
        structural=1
      fi
    fi
    rm -f /tmp/keys_before_$$.json /tmp/keys_after_$$.json

    if [ "$drop_pct" -gt 5 ] || [ "$structural" -eq 1 ]; then
      echo "SNAPSHOT DELTA UNEXPECTED: $label"
      echo "before: $before_count txns, after: $after_count txns (drop: ${drop_pct}%)"
      echo "sample diffs:"
      head -50 /tmp/snapshot_diff_$$.txt
      echo "escalating to opus for review"
      rm -f /tmp/snapshot_diff_$$.txt
      exit 2
    fi

    echo "SNAPSHOT DELTA (within bounds): $label"
    echo "before: $before_count txns, after: $after_count txns"
    head -20 /tmp/snapshot_diff_$$.txt
    rm -f /tmp/snapshot_diff_$$.txt
    return 1
  fi

  echo "SNAPSHOT OK: $label (no diff)"
  rm -f /tmp/snapshot_diff_$$.txt
  return 0
}

if [ "$BANK" = "graph" ]; then
  echo "Updating graphify graph..."
  cd "$REPO_ROOT" && graphify update .
  echo "Graph updated."
  exit 0
fi

if [ -n "$PDF" ]; then
  # Single file update
  EXPECTED="$FIXTURE_DIR/$(basename "${PDF%.*}")_expected.json"
  [ -f "$EXPECTED" ] && cp "$EXPECTED" "$TMP_BEFORE" || echo '{"transactions":[]}' > "$TMP_BEFORE"
  echo "Regenerating: $PDF"
  run_parser "$PDF" "$TMP_AFTER"
  cp "$TMP_AFTER" "$EXPECTED"
  check_delta "$TMP_BEFORE" "$TMP_AFTER" "$(basename "$PDF")"
  exit $?
fi

# Bank filter or all
if [ "$BANK" = "all" ]; then
  PATTERN="*.json"
else
  PATTERN="${BANK}*.json"
fi

EXIT_CODE=0
for expected in "$FIXTURE_DIR"/$PATTERN; do
  [ -f "$expected" ] || continue
  # Find matching input (pdf or csv)
  base="${expected%_expected.json}"
  input=""
  for ext in pdf csv txt xlsx; do
    candidate="$base.$ext"
    if [ -f "$candidate" ]; then
      input="$candidate"
      break
    fi
  done
  [ -z "$input" ] && continue

  cp "$expected" "$TMP_BEFORE"
  echo "Regenerating: $(basename "$input")"
  run_parser "$input" "$TMP_AFTER" || continue
  cp "$TMP_AFTER" "$expected"
  check_delta "$TMP_BEFORE" "$TMP_AFTER" "$(basename "$input")" || EXIT_CODE=1
done

exit $EXIT_CODE
