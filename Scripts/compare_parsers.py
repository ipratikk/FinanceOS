#!/usr/bin/env python3
"""Compare Swift parser output vs Python reference extraction."""

import json
import subprocess
import sys
from pathlib import Path
from collections import defaultdict


def run_swift_parser(pdf_path):
    """Run Swift CLI parser and return JSON output."""
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
                        return json.loads(output[start:start+i+1])
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


def analyze_differences(swift_txns, python_txns):
    """Compare transactions and identify differences."""
    swift_count = len(swift_txns)
    python_count = len(python_txns)

    # Build lookup by date + amount for matching
    swift_by_key = defaultdict(list)
    for t in swift_txns:
        key = (t["postedAt"], t["amountMinorUnits"])
        swift_by_key[key].append(t)

    python_by_key = defaultdict(list)
    for t in python_txns:
        # Convert date string to timestamp for comparison
        python_by_key[t["date"]].append(t)

    # Metrics
    empty_descriptions = sum(1 for t in swift_txns if t.get("description") == "HDFC Transaction")
    missing_entirely = python_count - swift_count

    return {
        "swift_count": swift_count,
        "python_count": python_count,
        "missing_from_swift": missing_entirely,
        "empty_descriptions_swift": empty_descriptions,
        "description_quality_swift": f"{100 * (swift_count - empty_descriptions) / max(1, swift_count):.1f}%",
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
    metrics = analyze_differences(
        swift_result.get("transactions", []),
        python_result.get("transactions", [])
    )

    print("\n=== COMPARISON RESULTS ===\n", file=sys.stderr)
    print(f"Swift parser:        {metrics['swift_count']:3d} transactions", file=sys.stderr)
    print(f"Python parser:       {metrics['python_count']:3d} transactions", file=sys.stderr)
    missing = metrics.get('missing_entirely', 0)
    py_count = metrics['python_count']
    if py_count > 0:
        print(f"Missing from Swift:  {missing:3d} ({100*missing/py_count:.1f}%)", file=sys.stderr)
    print(f"\nDescription quality:", file=sys.stderr)
    print(f"  Swift empty:       {metrics['empty_descriptions_swift']:3d} ({metrics['description_quality_swift']})", file=sys.stderr)
    print(f"  Python empty:      {sum(1 for t in python_result.get('transactions', []) if not t.get('description'))}", file=sys.stderr)

    # Output JSON comparison
    output = {
        "pdf_path": pdf_path,
        "metrics": metrics,
        "swift_sample": swift_result.get("transactions", [])[:3],
        "python_sample": python_result.get("transactions", [])[:3],
    }
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
