#!/usr/bin/env python3
"""Extract HDFC bank statements from PDF using pdfplumber."""

import json
import sys
from datetime import datetime
from pathlib import Path

import pdfplumber


def extract_text_with_positions(pdf_path):
    """Extract text preserving position information for table detection."""
    with pdfplumber.open(pdf_path) as pdf:
        transactions = []
        for page_num, page in enumerate(pdf.pages):
            chars = page.chars
            if not chars:
                continue

            # Group chars by y-coordinate (roughly by line)
            lines_dict = {}
            for char in chars:
                y = round(char["top"], 1)
                if y not in lines_dict:
                    lines_dict[y] = []
                lines_dict[y].append(char)

            # Sort by y position and reconstruct lines with position
            for y in sorted(lines_dict.keys()):
                line_chars = sorted(lines_dict[y], key=lambda c: c["x0"])
                text = "".join(c["text"] for c in line_chars)
                if text.strip():
                    transactions.append({
                        "page": page_num,
                        "y": y,
                        "text": text,
                        "x_range": (line_chars[0]["x0"], line_chars[-1]["x1"]),
                    })

        return transactions


def extract_tables(pdf_path):
    """Extract tables from PDF using pdfplumber's table detection."""
    with pdfplumber.open(pdf_path) as pdf:
        all_tables = []
        for page_num, page in enumerate(pdf.pages):
            try:
                tables = page.extract_tables()
                if tables:
                    for table_idx, table in enumerate(tables):
                        all_tables.append({
                            "page": page_num,
                            "table_idx": table_idx,
                            "data": table,
                        })
            except Exception as e:
                print(f"Error extracting tables from page {page_num}: {e}", file=sys.stderr)

        return all_tables


def parse_hdfc_transactions(table_data):
    """Parse HDFC transaction table into normalized format.

    Handles pdfplumber's table detection which combines rows into cells with newlines.
    Expected format: [Date | Narration | Ref | ValueDt | Debit | Credit | Balance]
    """
    transactions = []

    if not table_data or len(table_data) < 2:
        return transactions

    # Get header row to find column indices
    header_row = table_data[0]

    # For single-row tables (common with pdfplumber PDF detection),
    # cells contain newline-separated values
    if len(table_data) == 1 or len(table_data) == 2:
        # Check if first data row has newline-separated values
        if len(table_data) > 1:
            data_row = table_data[1]
        else:
            data_row = table_data[0]

        if data_row and any('\n' in str(cell) for cell in data_row if cell):
            # Split each cell by newlines to reconstruct rows
            split_cells = []
            for cell in data_row:
                if cell and '\n' in str(cell):
                    split_cells.append(str(cell).split('\n'))
                elif cell:
                    split_cells.append([str(cell)])
                else:
                    split_cells.append([''])

            # Determine number of rows
            num_rows = max(len(col) for col in split_cells)

            # Reconstruct individual transaction rows
            for row_idx in range(num_rows):
                row_values = []
                for col_idx, col in enumerate(split_cells):
                    if row_idx < len(col):
                        row_values.append(col[row_idx])
                    else:
                        row_values.append('')

                if len(row_values) >= 3:
                    transactions.append(row_values)

        else:
            # Normal table format - process as is
            for row in table_data[1:]:
                if row:
                    transactions.append(row)

    # Parse each reconstructed row
    parsed = []
    for row in transactions:
        if not row or len(row) < 3:
            continue

        # Skip header rows
        if any(kw in str(row[0]).lower() for kw in ["date", "narration", "debit", "credit"]):
            continue

        # Skip empty rows
        if all(not str(cell).strip() for cell in row):
            continue

        try:
            date_str = str(row[0]).strip() if row[0] else None
            narration = str(row[1]).strip() if len(row) > 1 else ""

            # Find debit/credit columns (may vary by position)
            debit_str = ""
            credit_str = ""

            if len(row) > 4:
                debit_str = str(row[4]).strip() if row[4] else ""
                credit_str = str(row[5]).strip() if len(row) > 5 and row[5] else ""

            # Fallback if columns not found
            if not debit_str and not credit_str and len(row) > 2:
                # Try to find amounts in any column after narration
                for i in range(3, len(row)):
                    val = str(row[i]).strip()
                    if val and any(c.isdigit() for c in val):
                        if not credit_str:
                            credit_str = val
                        else:
                            debit_str = val
                            break

            if not date_str or (not debit_str and not credit_str):
                continue

            # Parse amount
            amount_str = (credit_str or debit_str).replace(",", "").strip()
            try:
                amount = float(amount_str)
            except ValueError:
                continue

            # Determine sign
            if debit_str:
                try:
                    debit_val = float(debit_str.replace(",", ""))
                    if debit_val > 0:
                        amount = -amount
                except ValueError:
                    pass

            parsed.append({
                "date": date_str,
                "description": narration,
                "amount_minor_units": int(amount * 100),
                "debit": float(debit_str.replace(",", "")) if debit_str else 0,
                "credit": float(credit_str.replace(",", "")) if credit_str else 0,
            })
        except (ValueError, IndexError) as e:
            continue

    return parsed


def main():
    if len(sys.argv) < 2:
        print("Usage: python extract_hdfc_pdf.py <pdf_path> [--debug]")
        sys.exit(1)

    pdf_path = sys.argv[1]
    debug = "--debug" in sys.argv

    if not Path(pdf_path).exists():
        print(f"Error: File not found: {pdf_path}", file=sys.stderr)
        sys.exit(1)

    print(f"Extracting from: {pdf_path}")

    # Extract tables
    print("Finding tables...", file=sys.stderr)
    tables_data = extract_tables(pdf_path)

    if not tables_data:
        print("Error: No tables found in PDF", file=sys.stderr)
        if debug:
            print("\nExtracted text lines (first 50):", file=sys.stderr)
            text_lines = extract_text_with_positions(pdf_path)
            for line in text_lines[:50]:
                print(f"  y={line['y']:6.1f} x={line['x_range'][0]:6.1f}-{line['x_range'][1]:6.1f}: {line['text'][:80]}", file=sys.stderr)
        sys.exit(1)

    print(f"Found {len(tables_data)} table(s)", file=sys.stderr)

    # Parse transactions from first table (main transaction table)
    if tables_data:
        main_table = tables_data[0]["data"]
        transactions = parse_hdfc_transactions(main_table)

        result = {
            "bank_name": "HDFC",
            "transaction_count": len(transactions),
            "transactions": transactions,
        }

        # Output JSON
        print(json.dumps(result, indent=2, default=str))

        if debug:
            print(f"\nParsed {len(transactions)} transactions", file=sys.stderr)
            if transactions:
                print("First transaction:", file=sys.stderr)
                print(json.dumps(transactions[0], indent=2, default=str), file=sys.stderr)


if __name__ == "__main__":
    main()
