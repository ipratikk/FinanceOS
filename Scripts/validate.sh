#!/bin/bash

# Validate a statement file
# Usage: ./validate.sh <input_file> [--password <password>]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
INPUT_FILE="$1"

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: ./validate.sh <input_file> [--password <password>]"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file not found: $INPUT_FILE"
    exit 1
fi

cd "$PROJECT_DIR/Packages/FinanceParsers"

# Pass all remaining args to the CLI
shift
swift run FinanceParserCLI validate "$INPUT_FILE" "$@"
