#!/usr/bin/env python3
"""Extract HDFC bank statements using text-based parsing (reference implementation).

This parser uses pdfplumber to extract raw text, then intelligently reconstructs
transactions by recognizing that multi-line narrations continue until the next date line.
"""

import json
import sys
import re
from datetime import datetime
from pathlib import Path

import pdfplumber


def extract_text_lines(file_path):
    """Extract all text lines from PDF or TXT file."""
    lines = []
    path = Path(file_path)

    if path.suffix.lower() == '.txt':
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.read().split('\n')
    else:
        with pdfplumber.open(file_path) as pdf:
            for page in pdf.pages:
                text = page.extract_text()
                if text:
                    lines.extend(text.split('\n'))
    return lines


def is_csv_format(lines):
    """Check if file is CSV-formatted (has comma-separated columns)."""
    for line in lines[:20]:
        if ',' in line and any(kw in line.lower() for kw in ['date', 'narration', 'debit', 'credit']):
            return True
    return False


def parse_csv_format(lines, start_idx):
    """Parse CSV-formatted transaction file with variable-length narrations.

    Format: Date | Narration (variable length, may contain commas) | Value Date | Debit | Credit | Ref | Balance

    Re-anchors on value_date when narration contains commas. Works backward from end to identify
    debit/credit amounts reliably.
    """
    transactions = []

    # Parse header row
    header_line = lines[start_idx]
    headers = [h.strip().lower() for h in header_line.split(',')]

    # Find column indices
    date_idx = next((i for i, h in enumerate(headers) if 'date' in h), None)

    if date_idx is None:
        return []

    # Parse data rows
    for line in lines[start_idx + 1:]:
        if not line.strip():
            continue

        cols = [c.strip() for c in line.split(',')]
        if len(cols) < 5:  # Minimum: date, narr, debit, credit, ref
            continue

        date_str = cols[0]
        if not is_date_line(date_str):
            continue

        # Standard layout: [0]=date, [1]=narration, [2]=value_date, [3]=debit, [4]=credit, [5]=ref, [6]=balance
        # When narration has commas, it expands: [0]=date, [1..N]=narration_parts, [N+1]=value_date, [N+2]=debit, ...

        # Try to parse value_date at standard index 2
        value_date_str = cols[2] if len(cols) > 2 else ""
        try:
            parse_date(value_date_str)
            # Standard case
            narration = cols[1].strip()
            debit_str = cols[3] if len(cols) > 3 else "0"
            credit_str = cols[4] if len(cols) > 4 else "0"
        except ValueError:
            # Re-anchor: narration contains commas. Find value_date by scanning backward from end.
            # Last 4 cols are: [debit, credit, ref, balance]
            # Scan backward from position len(cols)-4 to find first valid date (value_date).
            anchor = None
            for i in range(len(cols) - 4, 1, -1):
                try:
                    parse_date(cols[i])
                    anchor = i
                    break
                except ValueError:
                    continue

            if anchor is None:
                continue  # Cannot locate value_date

            value_date_str = cols[anchor]
            debit_str = cols[anchor + 1] if anchor + 1 < len(cols) else "0"
            credit_str = cols[anchor + 2] if anchor + 2 < len(cols) else "0"
            narration = ",".join(cols[1:anchor]).strip()

        debit = parse_amount(debit_str) or 0.0
        credit = parse_amount(credit_str) or 0.0

        if debit == 0 and credit == 0:
            continue

        # Calculate amount_minor_units: positive for debit, negative for credit
        # (matches Swift parser convention)
        if debit > 0:
            amount_minor = round(debit * 100)
        else:
            amount_minor = round(-credit * 100)

        transactions.append({
            'date': date_str,
            'description': narration,
            'amount_minor_units': int(amount_minor),
            'debit': debit,
            'credit': credit,
        })

    return transactions


def find_table_start(lines):
    """Find the start of the transaction table."""
    for i, line in enumerate(lines):
        if 'Date' in line and ('Narration' in line or 'narration' in line.lower()):
            return i
    return -1


def is_date_line(text):
    """Check if line starts with a transaction date (dd/mm/yy format)."""
    return bool(re.match(r'^\s*\d{2}/\d{2}/\d{2}', text))


def parse_date(s: str) -> datetime:
    """Parse date in dd/mm/yy or dd/mm/yyyy format."""
    s = s.strip()
    for fmt in ("%d/%m/%y", "%d/%m/%Y"):
        try:
            return datetime.strptime(s, fmt)
        except ValueError:
            continue
    raise ValueError(f"Cannot parse date: {s!r}")


def parse_amount(amount_str):
    """Parse amount string to float."""
    if not amount_str or not amount_str.strip():
        return None
    try:
        return float(amount_str.replace(',', '').strip())
    except ValueError:
        return None


def reconstruct_transactions(lines, start_idx):
    """Reconstruct transactions from raw text lines.

    Strategy: Group lines by transaction. A transaction starts with a date line.
    Subsequent lines that don't start with dates are continuations of the narration.
    Amount columns appear after the narration.
    """
    transactions = []
    current_txn = None

    i = start_idx + 1  # Skip header

    while i < len(lines):
        line = lines[i]

        if not line.strip():
            i += 1
            continue

        # Check if this is a new transaction (starts with date)
        if is_date_line(line):
            # Save previous transaction if exists
            if current_txn:
                transactions.append(current_txn)

            # Parse new transaction line
            parts = line.split()
            if len(parts) >= 1:
                date = parts[0]
                current_txn = {
                    'date': date,
                    'narration_lines': [],
                    'amounts': [],
                    'raw_line': line,
                }

                # Extract any amounts from this line
                for part in parts:
                    amount = parse_amount(part)
                    if amount is not None:
                        current_txn['amounts'].append(amount)
            else:
                current_txn = None

        elif current_txn:
            # Continuation of current transaction's narration
            current_txn['narration_lines'].append(line.strip())

            # Extract amounts from continuation lines
            for part in line.split():
                amount = parse_amount(part)
                if amount is not None:
                    current_txn['amounts'].append(amount)

        i += 1

    # Don't forget last transaction
    if current_txn:
        transactions.append(current_txn)

    return transactions


def extract_debit_credit(amounts):
    """Heuristic: determine debit/credit from amounts.

    For HDFC format: [debit, credit, balance] or [debit, credit]
    Filter out values > 50M paise (likely balances/cardnumbers).
    """
    if not amounts:
        return None, None

    # Filter large amounts (balance, not transaction)
    filtered = [a for a in amounts if a < 500000]

    if len(filtered) == 0:
        return None, None
    elif len(filtered) == 1:
        return None, filtered[0]
    elif len(filtered) >= 2:
        return filtered[0], filtered[1]
    else:
        return None, filtered[0] if filtered else None


def parse_hdfc_transactions(transactions):
    """Convert reconstructed transactions to normalized format."""
    parsed = []

    for txn in transactions:
        date = txn.get('date')
        if not date:
            continue

        # Merge narration lines
        narration = ' '.join(txn.get('narration_lines', [])).strip()

        # Extract debit/credit
        amounts = txn.get('amounts', [])
        debit, credit = extract_debit_credit(amounts)

        if not (debit or credit):
            continue

        # Determine amount and sign
        if debit and credit:
            if debit > 0 and credit == 0:
                amount_minor = int(-debit * 100)
            elif credit > 0 and debit == 0:
                amount_minor = int(credit * 100)
            else:
                amount_minor = int((credit - debit) * 100)
        elif credit:
            amount_minor = int(credit * 100)
        else:
            amount_minor = int(-debit * 100)

        parsed.append({
            'date': date,
            'description': narration,
            'amount_minor_units': amount_minor,
            'debit': debit if debit else 0,
            'credit': credit if credit else 0,
        })

    return parsed


def main():
    if len(sys.argv) < 2:
        print("Usage: python extract_hdfc_reference.py <pdf_or_txt_path>")
        sys.exit(1)

    file_path = sys.argv[1]
    if not Path(file_path).exists():
        print(f"Error: File not found: {file_path}", file=sys.stderr)
        sys.exit(1)

    print(f"Extracting from: {file_path}", file=sys.stderr)

    # Extract raw text
    lines = extract_text_lines(file_path)
    print(f"Extracted {len(lines)} text lines", file=sys.stderr)

    # Find table start
    start_idx = find_table_start(lines)
    if start_idx < 0:
        print("Error: Transaction table not found", file=sys.stderr)
        sys.exit(1)

    print(f"Transaction table starts at line {start_idx}", file=sys.stderr)

    # Check if CSV-formatted and parse accordingly
    if is_csv_format(lines):
        print("Detected CSV format", file=sys.stderr)
        parsed = parse_csv_format(lines, start_idx)
        print(f"Parsed {len(parsed)} transactions from CSV", file=sys.stderr)
    else:
        # Reconstruct transactions (PDF format)
        txns = reconstruct_transactions(lines, start_idx)
        print(f"Reconstructed {len(txns)} transactions", file=sys.stderr)

        # Parse to normalized format
        parsed = parse_hdfc_transactions(txns)
        print(f"Parsed {len(parsed)} valid transactions", file=sys.stderr)

    # Output JSON
    result = {
        "bank_name": "HDFC",
        "transaction_count": len(parsed),
        "transactions": parsed,
    }
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
