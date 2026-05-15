#!/usr/bin/env python3
"""Inspect HDFC PDF structure to understand table layout."""

import sys
from pathlib import Path
import pdfplumber
import json

pdf_path = sys.argv[1] if len(sys.argv) > 1 else None
if not pdf_path or not Path(pdf_path).exists():
    print("Usage: python inspect_hdfc_pdf.py <pdf_path>")
    sys.exit(1)

with pdfplumber.open(pdf_path) as pdf:
    print(f"PDF: {pdf_path}")
    print(f"Pages: {len(pdf.pages)}")

    for page_num, page in enumerate(pdf.pages):
        print(f"\n=== PAGE {page_num} ===")

        # Extract text
        text = page.extract_text()
        if text:
            lines = text.split('\n')
            print(f"Text lines: {len(lines)}")

            # Find transaction table header
            for i, line in enumerate(lines):
                if 'Date' in line and ('Narration' in line or 'narration' in line.lower()):
                    print(f"\nTransaction table header at line {i}:")
                    print(f"  {line}")
                    print(f"\nNext 20 lines:")
                    for j in range(i+1, min(i+21, len(lines))):
                        print(f"  {j}: {lines[j][:100]}")
                    break

        # Extract tables
        tables = page.extract_tables()
        if tables:
            print(f"\nTables detected: {len(tables)}")
            for t_idx, table in enumerate(tables):
                print(f"\nTable {t_idx}: {len(table)} rows")
                if table:
                    print(f"  Row 0 (header): {table[0][:4]}")
                    if len(table) > 1:
                        print(f"  Row 1 (sample): {table[1][:4]}")
