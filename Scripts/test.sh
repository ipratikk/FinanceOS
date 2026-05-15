#!/bin/bash
# Test runner with xcbeautify fallback
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

TEST_CMD="xcodebuild test -workspace FinanceOS.xcworkspace -scheme FinanceOSMac -destination 'platform=macOS'"

if command -v xcbeautify &> /dev/null; then
    echo "Running tests (with xcbeautify)..."
    eval "$TEST_CMD" | xcbeautify
else
    echo "Running tests (xcbeautify not found, using raw output)..."
    eval "$TEST_CMD"
fi

echo "✓ Tests complete"
