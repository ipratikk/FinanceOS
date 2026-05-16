#!/usr/bin/env python3
"""Compare Swift parser output vs Python reference extraction."""

import json
import subprocess
import sys
from pathlib import Path
from collections import defaultdict


def run_swift_parser(pdf_path):
    """Run Swift CLI parser and return parsed transactions."""
    script_dir = Path(__file__).parent.parent / "Packages" / "FinanceParsers"
    try:
        result = subprocess.run(
            ["swift", "run", "-c", "release", "FinanceParserCLI", "parse", str(pdf_path)],
            cwd=script_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=60
        )
        if result.returncode != 0:
            return None

        # Extract JSON from output (skip build output)
        output = result.stdout
        if '{' in output:
            start = output.index('{')
            # Find matching closing brace
            depth = 0
            for i, c in enumerate(output[start:]):
                if c == '{':
                    depth += 1
                elif c == '}':
                    depth -= 1
                    if depth == 0:
                        data = json.loads(output[start:start+i+1])
                        # Extract transactions from nested structure
                        return {
                            "transactions": data.get("statement", {}).get("transactions", []),
                            "total_credit": data.get("statement", {}).get("totalCredit", 0),
                            "total_debit": data.get("statement", {}).get("totalDebit", 0),
                        }
        return None
    except Exception as e:
        print(f"Error running Swift parser: {e}", file=sys.stderr)
        return None


def run_python_parser(pdf_path):
    """Run Python reference parser and return JSON output."""
    script_dir = Path(__file__).parent
    try:
        result = subprocess.run(
            ["python3", str(script_dir / "extract_hdfc_reference.py"), str(pdf_path)],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=60
        )
        if result.returncode != 0:
            return None

        # Find JSON in output (skip any stderr lines that got mixed in)
        output = result.stdout
        if '{' in output:
            start = output.index('{')
            # Find matching closing brace
            depth = 0
            for i, c in enumerate(output[start:]):
                if c == '{':
                    depth += 1
                elif c == '}':
                    depth -= 1
                    if depth == 0:
                        return json.loads(output[start:start+i+1])
        return None
    except Exception as e:
        print(f"Error running Python parser: {e}", file=sys.stderr)
        return None


def extract_date_from_fingerprint(fingerprint):
    """Extract date from sourceFingerprint (format: dd/mm/yy|...)."""
    if fingerprint:
        parts = fingerprint.split("|")
        return parts[0] if parts else ""
    return ""


def analyze_differences(swift_txns, python_txns, swift_totals=None, python_totals=None):
    """Comprehensive comparison of parsed transactions."""
    swift_count = len(swift_txns)
    python_count = len(python_txns)

    # Match transactions by date + amount
    matched = []
    matched_python_indices = set()

    for s_txn in swift_txns:
        # Extract date from Swift's sourceFingerprint (more reliable)
        s_date = extract_date_from_fingerprint(s_txn.get("sourceFingerprint", ""))
        s_amount = s_txn.get("amountMinorUnits", 0)

        for p_idx, p_txn in enumerate(python_txns):
            if p_idx in matched_python_indices:
                continue

            p_date = p_txn.get("date", "")
            p_amount = p_txn.get("amount_minor_units", 0)

            # Match by date and absolute amount (signs may differ)
            if s_date == p_date and abs(s_amount) == abs(p_amount):
                matched.append({
                    "swift": s_txn,
                    "python": p_txn,
                    "date_match": True,
                    "amount_match": s_amount == p_amount,
                    "description_match": s_txn.get("description", "") == p_txn.get("description", ""),
                })
                matched_python_indices.add(p_idx)
                break

    unmatched_swift = [t for i, t in enumerate(swift_txns) if not any(m["swift"] == t for m in matched)]
    unmatched_python = [t for i, t in enumerate(python_txns) if i not in matched_python_indices]

    # Calculate totals
    swift_total_debit = sum(abs(t.get("amountMinorUnits", 0)) for t in swift_txns if t.get("amountMinorUnits", 0) > 0)
    swift_total_credit = sum(abs(t.get("amountMinorUnits", 0)) for t in swift_txns if t.get("amountMinorUnits", 0) < 0)

    # Python: negative = debit, positive = credit (opposite of Swift)
    python_total_debit = 0
    python_total_credit = 0
    for t in python_txns:
        amount = t.get("amount_minor_units", 0)
        if amount < 0:
            python_total_debit += abs(amount)  # Negative amounts are debits
        elif amount > 0:
            python_total_credit += abs(amount)  # Positive amounts are credits

    # Check for description mismatches (accounting for empty descriptions)
    description_issues = sum(1 for m in matched
                            if m["swift"]["description"] and not m["python"].get("description")
                            and m["swift"]["description"] != m["python"].get("description", ""))

    # Check for amount sign mismatches (common between parsers with different conventions)
    amount_issues = sum(1 for m in matched if m["swift"].get("amountMinorUnits") != m["python"].get("amount_minor_units"))

    return {
        "swift_count": swift_count,
        "python_count": python_count,
        "matched_count": len(matched),
        "unmatched_swift_count": len(unmatched_swift),
        "unmatched_python_count": len(unmatched_python),
        "swift_total_debit": swift_total_debit,
        "swift_total_credit": swift_total_credit,
        "python_total_debit": python_total_debit,
        "python_total_credit": python_total_credit,
        "description_mismatches": description_issues,
        "amount_mismatches": amount_issues,
        "matched": matched,
        "unmatched_swift": unmatched_swift,
        "unmatched_python": unmatched_python,
    }


def main():
    if len(sys.argv) < 2:
        print("Usage: python compare_parsers.py <pdf_path>")
        sys.exit(1)

    pdf_path = sys.argv[1]
    if not Path(pdf_path).exists():
        print(f"Error: File not found: {pdf_path}", file=sys.stderr)
        sys.exit(1)

    print(f"Comparing parsers on: {pdf_path}\n", file=sys.stderr)

    # Run both parsers
    print("Running Swift parser...", file=sys.stderr, end=" ", flush=True)
    swift_result = run_swift_parser(pdf_path)
    if swift_result:
        swift_count = len(swift_result.get('transactions', []))
        print(f"✓ ({swift_count} txns)", file=sys.stderr)
    else:
        print("✗ Failed", file=sys.stderr)
        swift_result = {"transactions": []}

    print("Running Python reference parser...", file=sys.stderr, end=" ", flush=True)
    python_result = run_python_parser(pdf_path)
    if python_result:
        python_count = len(python_result.get('transactions', []))
        print(f"✓ ({python_count} txns)", file=sys.stderr)
    else:
        print("✗ Failed", file=sys.stderr)
        python_result = {"transactions": []}

    # Analyze
    swift_txns = swift_result.get("transactions", [])
    python_txns = python_result.get("transactions", [])

    metrics = analyze_differences(
        swift_txns,
        python_txns,
        swift_totals={
            "debit": swift_result.get("total_debit", 0),
            "credit": swift_result.get("total_credit", 0),
        },
        python_totals=python_result.get("totals", {})
    )

    print("\n=== COMPARISON RESULTS ===\n", file=sys.stderr)
    print(f"Transaction Count:", file=sys.stderr)
    print(f"  Swift:           {metrics['swift_count']:4d}", file=sys.stderr)
    print(f"  Python:          {metrics['python_count']:4d}", file=sys.stderr)
    print(f"  Matched:         {metrics['matched_count']:4d}", file=sys.stderr)
    print(f"  Unmatched Swift: {metrics['unmatched_swift_count']:4d}", file=sys.stderr)
    print(f"  Unmatched Python:{metrics['unmatched_python_count']:4d}", file=sys.stderr)

    print(f"\nAmount Totals (in paise):", file=sys.stderr)
    print(f"  Swift  - Debit:  {metrics['swift_total_debit']:10d}", file=sys.stderr)
    print(f"  Swift  - Credit: {metrics['swift_total_credit']:10d}", file=sys.stderr)
    print(f"  Python - Debit:  {metrics['python_total_debit']:10d}", file=sys.stderr)
    print(f"  Python - Credit: {metrics['python_total_credit']:10d}", file=sys.stderr)

    print(f"\nData Quality:", file=sys.stderr)
    print(f"  Description mismatches: {metrics['description_mismatches']}", file=sys.stderr)
    print(f"  Amount mismatches:      {metrics['amount_mismatches']}", file=sys.stderr)

    # Determine status - check both transaction count AND total amount accuracy
    unmatched_gap = max(metrics['unmatched_swift_count'], metrics['unmatched_python_count'])

    # Calculate actual amount delta as percentage of total
    debit_delta = abs(metrics['swift_total_debit'] - metrics['python_total_debit'])
    credit_delta = abs(metrics['swift_total_credit'] - metrics['python_total_credit'])
    total_amount = metrics['swift_total_debit'] + metrics['swift_total_credit']
    amount_delta_pct = 100 * (debit_delta + credit_delta) / max(1, total_amount * 2) if total_amount > 0 else 0

    if unmatched_gap == 0 and amount_delta_pct < 0.5:  # Less than 0.5% variance
        gap_pct = amount_delta_pct
        status = "PASS"
    elif unmatched_gap > 0:
        gap_pct = 100 * unmatched_gap / max(1, metrics['python_count'])
        status = "GAP" if gap_pct <= 5 else "FAIL"
    elif amount_delta_pct >= 0.5:
        gap_pct = amount_delta_pct
        status = "GAP" if amount_delta_pct <= 5 else "FAIL"
    else:
        gap_pct = 0
        status = "PASS"

    print(f"\nStatus: {status} ({gap_pct:.1f}% gap)", file=sys.stderr)

    # Output JSON comparison
    output = {
        "file_path": pdf_path,
        "status": status,
        "gap_percent": gap_pct,
        "metrics": {
            "swift_count": metrics['swift_count'],
            "python_count": metrics['python_count'],
            "matched": metrics['matched_count'],
            "unmatched_swift": metrics['unmatched_swift_count'],
            "unmatched_python": metrics['unmatched_python_count'],
            "description_mismatches": metrics['description_mismatches'],
            "amount_mismatches": metrics['amount_mismatches'],
        },
        "totals": {
            "swift_debit": metrics['swift_total_debit'],
            "swift_credit": metrics['swift_total_credit'],
            "python_debit": metrics['python_total_debit'],
            "python_credit": metrics['python_total_credit'],
        },
        "issues": {
            "unmatched_swift": metrics['unmatched_swift'][:5] if metrics['unmatched_swift'] else [],
            "unmatched_python": metrics['unmatched_python'][:5] if metrics['unmatched_python'] else [],
        }
    }
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
