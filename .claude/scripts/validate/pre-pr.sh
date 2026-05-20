#!/usr/bin/env bash
# pre-pr.sh — Local CI validation mirroring .github/workflows/swift.yml
#
# Jobs (same order as CI):
#   1. SwiftLint     — changed Swift files only (strict mode)
#   2. Package Tests — swift test --parallel for each affected package
#   3. macOS Build   — xcodebuild -scheme FinanceOSMac
#
# Usage:
#   .claude/scripts/validate/pre-pr.sh            # vs origin/main
#   .claude/scripts/validate/pre-pr.sh main       # vs local main
#   .claude/scripts/validate/pre-pr.sh --lint-only
#
# Exit codes:
#   0 = all pass
#   1 = lint errors
#   2 = test failures
#   3 = build failure

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
BASE="origin/main"
LINT_ONLY=0

for arg in "$@"; do
  case "$arg" in
    --lint-only) LINT_ONLY=1 ;;
    *) BASE="$arg" ;;
  esac
done

PASS=0
FAIL=0
FAIL_REASON=0

red()    { printf '\033[0;31m✗ %s\033[0m\n' "$*"; }
green()  { printf '\033[0;32m✓ %s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m⚠ %s\033[0m\n' "$*"; }
bold()   { printf '\n\033[1m── %s ──\033[0m\n' "$*"; }

# ─────────────────────────────────────────────
# Changed files
# ─────────────────────────────────────────────

CHANGED_SWIFT=$(git diff --name-only "$BASE"...HEAD 2>/dev/null | grep '\.swift$' || true)

if [ -z "$CHANGED_SWIFT" ]; then
  yellow "No Swift files changed vs $BASE — nothing to validate"
  exit 0
fi

CHANGED_COUNT=$(echo "$CHANGED_SWIFT" | wc -l | tr -d ' ')
echo "Changed Swift files vs $BASE: $CHANGED_COUNT"

# ─────────────────────────────────────────────
# Job 1: SwiftLint
# ─────────────────────────────────────────────

bold "Job 1: SwiftLint"

LINT_ERRORS=0
while IFS= read -r file; do
  [ -z "$file" ] && continue
  [ -f "$REPO_ROOT/$file" ] || continue
  VIOLATIONS=$(swiftlint lint --strict --quiet --path "$REPO_ROOT/$file" 2>/dev/null || true)
  ERRORS=$(echo "$VIOLATIONS" | grep -c "error:" || echo 0)
  if [ "$ERRORS" -gt 0 ]; then
    echo "$VIOLATIONS" | grep "error:" | head -5
    LINT_ERRORS=$((LINT_ERRORS + ERRORS))
  fi
done <<< "$CHANGED_SWIFT"

if [ "$LINT_ERRORS" -eq 0 ]; then
  green "SwiftLint passed"
  PASS=$((PASS + 1))
else
  red "SwiftLint: $LINT_ERRORS error(s) — run /lint fix before creating PR"
  FAIL=$((FAIL + 1))
  FAIL_REASON=1
fi

[ "$LINT_ONLY" -eq 1 ] && { [ "$FAIL" -eq 0 ] && exit 0 || exit "$FAIL_REASON"; }

# ─────────────────────────────────────────────
# Job 2: Package Tests (affected packages only)
# ─────────────────────────────────────────────

bold "Job 2: Package Tests"

PACKAGES=(FinanceCore FinanceParsers FinanceUI FinanceTesting)
TESTED=0

for PKG in "${PACKAGES[@]}"; do
  PKG_PATH="$REPO_ROOT/Packages/$PKG"
  [ -d "$PKG_PATH" ] || continue

  HAS_CHANGES=$(echo "$CHANGED_SWIFT" | grep -c "Packages/$PKG/" || echo 0)
  [ "$HAS_CHANGES" -eq 0 ] && continue

  TESTED=$((TESTED + 1))
  echo "Testing $PKG ($HAS_CHANGES file(s) changed)..."

  LOG="/tmp/pre-pr-test-$PKG.log"
  if swift test \
      --package-path "$PKG_PATH" \
      --parallel \
      2>&1 | tee "$LOG" | grep -E "Test Suite|error:|FAILED|passed|failed" | tail -5; then

    if grep -q "FAILED\|error:" "$LOG" 2>/dev/null; then
      red "$PKG tests FAILED"
      grep -E "FAILED|error:" "$LOG" | head -10 | sed 's/^/  /'
      FAIL=$((FAIL + 1))
      [ "$FAIL_REASON" -lt 2 ] && FAIL_REASON=2
    else
      green "$PKG tests passed"
      PASS=$((PASS + 1))
    fi
  else
    red "$PKG tests FAILED"
    FAIL=$((FAIL + 1))
    [ "$FAIL_REASON" -lt 2 ] && FAIL_REASON=2
  fi
done

[ "$TESTED" -eq 0 ] && yellow "No package changes — tests skipped"

# ─────────────────────────────────────────────
# Job 3: macOS Build
# ─────────────────────────────────────────────

bold "Job 3: macOS Build"

WORKSPACE="$REPO_ROOT/FinanceOS.xcworkspace"

if [ ! -d "$WORKSPACE" ]; then
  yellow "Workspace not found — skipping macOS build"
else
  BUILD_LOG="/tmp/pre-pr-macos-build.log"
  echo "Building FinanceOSMac..."
  if xcodebuild \
      build \
      -workspace "$WORKSPACE" \
      -scheme FinanceOSMac \
      -destination 'platform=macOS,arch=arm64' \
      COMPILER_INDEX_STORE_ENABLE=NO \
      -parallelizeTargets \
      -quiet \
      2>&1 | tee "$BUILD_LOG" | grep -E "error:|BUILD (SUCCEEDED|FAILED)" | head -20; then

    if grep -q "BUILD FAILED\|error:" "$BUILD_LOG" 2>/dev/null; then
      red "macOS build FAILED"
      grep "error:" "$BUILD_LOG" | head -10 | sed 's/^/  /'
      FAIL=$((FAIL + 1))
      [ "$FAIL_REASON" -lt 3 ] && FAIL_REASON=3
    else
      green "macOS build succeeded"
      PASS=$((PASS + 1))
    fi
  else
    red "macOS build FAILED"
    FAIL=$((FAIL + 1))
    [ "$FAIL_REASON" -lt 3 ] && FAIL_REASON=3
  fi
fi

# ─────────────────────────────────────────────
# Validation Summary
# ─────────────────────────────────────────────

bold "Validation Summary"
echo "Passed: $PASS  Failed: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  red "Pre-PR validation FAILED — fix issues before creating PR"
  exit "$FAIL_REASON"
fi

green "All checks passed. Ready to create PR."
exit 0
