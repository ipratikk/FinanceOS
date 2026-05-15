#!/bin/bash
# Clean build artifacts
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "Cleaning macOS build artifacts..."
xcodebuild clean -workspace FinanceOS.xcworkspace -scheme FinanceOSMac -quiet

echo "Cleaning iOS build artifacts..."
xcodebuild clean -workspace FinanceOS.xcworkspace -scheme FinanceOSiOS -quiet

echo "Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/FinanceOS-* 2>/dev/null || true

echo "✓ Clean complete"
