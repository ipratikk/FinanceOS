#!/bin/bash

# Parse all statement files in a directory
# Usage: ./batch_parse.sh <input_dir> [output_dir]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
INPUT_DIR="$1"
OUTPUT_DIR="${2:-.}"

if [ -z "$INPUT_DIR" ]; then
    echo "Usage: ./batch_parse.sh <input_dir> [output_dir]"
    exit 1
fi

if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory not found: $INPUT_DIR"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "Parsing statements from: $INPUT_DIR"
echo "Output directory: $OUTPUT_DIR"

cd "$PROJECT_DIR/Packages/FinanceParsers"

# Count files
count=0
for format in pdf csv txt xlsx; do
    count=$((count + $(find "$INPUT_DIR" -maxdepth 1 -type f -iname "*.$format" | wc -l)))
done

if [ "$count" -eq 0 ]; then
    echo "No statement files found (*.pdf, *.csv, *.txt, *.xlsx)"
    exit 0
fi

echo "Found $count statement files to parse..."

for file in "$INPUT_DIR"/*.{pdf,PDF,csv,CSV,txt,TXT,xlsx,XLSX}; do
    [ -e "$file" ] || continue

    filename=$(basename "$file")
    output_file="$OUTPUT_DIR/${filename%.*}.json"

    echo "Parsing: $filename -> ${filename%.*}.json"
    swift run FinanceParserCLI parse "$file" --json > "$output_file" 2>/dev/null || {
        echo "  ✗ Failed to parse $filename"
        rm -f "$output_file"
    }
done

echo "Batch parsing complete"
