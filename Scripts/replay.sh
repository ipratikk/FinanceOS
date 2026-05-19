#!/bin/bash

# Replay all fixtures in a directory
# Usage: ./replay.sh [fixtures_dir]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
FIXTURES_DIR="${1:-.}"

if [ ! -d "$FIXTURES_DIR" ]; then
    echo "Error: Fixtures directory not found: $FIXTURES_DIR"
    exit 1
fi

echo "Replaying fixtures from: $FIXTURES_DIR"

cd "$PROJECT_DIR/Packages/FinanceParsers"

swift run FinanceParserCLI replay --fixtures "$FIXTURES_DIR"
