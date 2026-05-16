#!/bin/bash

# List all registered statement sources
# Usage: ./list-sources.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR/Packages/FinanceParsers"

swift run FinanceParserCLI list-sources
