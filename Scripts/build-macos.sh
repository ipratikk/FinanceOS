#!/bin/bash
# macOS build script with xcbeautify fallback
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

BUILD_CMD="xcodebuild -workspace FinanceOS.xcworkspace -scheme FinanceOSMac -destination 'platform=macOS' -quiet build"

if command -v xcbeautify &> /dev/null; then
    echo "Building macOS (with xcbeautify)..."
    eval "$BUILD_CMD" | xcbeautify
else
    echo "Building macOS (xcbeautify not found, using raw output)..."
    eval "$BUILD_CMD"
fi

echo "✓ macOS build complete"
