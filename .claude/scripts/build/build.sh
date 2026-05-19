#!/usr/bin/env bash
# build.sh [target]
#
# Targets:
#   core     — swift build FinanceCore
#   parsers  — swift build FinanceParsers
#   mac      — xcodebuild FinanceOSMac (default)
#   ios      — xcodebuild FinanceOSiOS
#   test     — swift test both packages
#   clean    — clean DerivedData + rebuild mac
#   all      — core + parsers + mac
#
# Exit codes:
#   0 = clean
#   1 = compile errors (haiku handles)
#   2 = linker / cross-target errors (escalate to sonnet)

set -euo pipefail

REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
CORE_PKG="$REPO_ROOT/Packages/FinanceCore"
PARSERS_PKG="$REPO_ROOT/Packages/FinanceParsers"
WORKSPACE="$REPO_ROOT/FinanceOS.xcworkspace"

TARGET="${1:-mac}"
START=$(date +%s)

die() {
  echo "Build failed: $1" >&2
  exit "${2:-1}"
}

build_core() {
  echo "Building FinanceCore..."
  swift build -c release --package-path "$CORE_PKG" 2>&1 \
    | grep -E "error:|warning:|Build complete" | head -40 \
    || die "FinanceCore" 1
}

build_parsers() {
  echo "Building FinanceParsers..."
  swift build -c release --package-path "$PARSERS_PKG" 2>&1 \
    | grep -E "error:|warning:|Build complete" | head -40 \
    || die "FinanceParsers" 1
}

build_mac() {
  echo "Building FinanceOSMac..."
  [ -d "$WORKSPACE" ] || die "workspace not found: $WORKSPACE" 2
  xcodebuild \
    -workspace "$WORKSPACE" \
    -scheme FinanceOSMac \
    -configuration Debug \
    -quiet \
    2>&1 | grep -E "error:|warning:|BUILD (SUCCEEDED|FAILED)" | head -40 \
    || die "FinanceOSMac" 1
}

build_ios() {
  echo "Building FinanceOSiOS..."
  [ -d "$WORKSPACE" ] || die "workspace not found: $WORKSPACE" 2
  xcodebuild \
    -workspace "$WORKSPACE" \
    -scheme FinanceOSiOS \
    -destination "platform=iOS Simulator,name=iPhone 16" \
    -configuration Debug \
    -quiet \
    2>&1 | grep -E "error:|warning:|BUILD (SUCCEEDED|FAILED)" | head -40 \
    || die "FinanceOSiOS" 1
}

build_test() {
  echo "Testing FinanceCore..."
  swift test --package-path "$CORE_PKG" 2>&1 | tail -20 || die "FinanceCore tests" 1
  echo "Testing FinanceParsers..."
  swift test --package-path "$PARSERS_PKG" 2>&1 | tail -20 || die "FinanceParsers tests" 1
}

build_clean() {
  echo "Cleaning DerivedData..."
  rm -rf ~/Library/Developer/Xcode/DerivedData/FinanceOS-*
  build_mac
}

case "$TARGET" in
  core)    build_core ;;
  parsers) build_parsers ;;
  mac)     build_mac ;;
  ios)     build_ios ;;
  test)    build_test ;;
  clean)   build_clean ;;
  all)     build_core && build_parsers && build_mac ;;
  *)       die "Unknown target: $TARGET. Use: core|parsers|mac|ios|test|clean|all" 1 ;;
esac

END=$(date +%s)
echo "Build complete ($TARGET, $((END - START))s)"
