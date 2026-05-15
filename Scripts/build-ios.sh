#!/bin/bash
# iOS simulator build script with xcbeautify fallback
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

BUILD_CMD="xcodebuild -workspace FinanceOS.xcworkspace -scheme FinanceOSiOS -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build"

if command -v xcbeautify &> /dev/null; then
    echo "Building iOS (with xcbeautify)..."
    eval "$BUILD_CMD" | xcbeautify
else
    echo "Building iOS (xcbeautify not found, using raw output)..."
    eval "$BUILD_CMD"
fi

echo "✓ iOS build complete"
