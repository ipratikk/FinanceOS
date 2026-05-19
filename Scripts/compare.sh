#!/bin/bash

# Compare parsed output with expected JSON
# Usage: ./compare.sh <input_file> [expected_json]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
INPUT_FILE="$1"
EXPECTED_FILE="$2"

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: ./compare.sh <input_file> [expected_json]"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file not found: $INPUT_FILE"
    exit 1
fi

cd "$PROJECT_DIR/Packages/FinanceParsers"

if [ -z "$EXPECTED_FILE" ]; then
    swift run FinanceParserCLI compare "$INPUT_FILE"
else
    if [ ! -f "$EXPECTED_FILE" ]; then
        echo "Error: Expected file not found: $EXPECTED_FILE"
        exit 1
    fi

    swift run FinanceParserCLI compare "$INPUT_FILE" --expected "$EXPECTED_FILE"
fi
