#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARSER_PKG="$REPO_ROOT/Packages/FinanceParsers"

echo "📦 Building FinanceParsers..."
cd "$PARSER_PKG"
swift build -c release

echo ""
echo "✅ Build successful"
echo ""

if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-statement-file>"
    echo ""
    echo "Example:"
    echo "  $0 ~/Documents/Acct_Statement_XXXXXXXX6521_15052026.pdf"
    exit 1
fi

FILE="$1"
if [ ! -f "$FILE" ]; then
    echo "❌ File not found: $FILE"
    exit 1
fi

echo "📄 Parsing: $FILE"
echo ""

swift run -c release FinanceParserCLI parse "$FILE"
