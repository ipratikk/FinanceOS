#!/usr/bin/env python3
"""
Run all 11 model benchmarks and produce consolidated report.

Usage:
  python scripts/run_all_benchmarks.py \\
    --dataset data/golden_transactions.jsonl \\
    --output reports/phase1_baseline.json
"""

import argparse
import json
import subprocess
from pathlib import Path
from datetime import datetime
import sys


BENCHMARK_SCRIPTS = [
    "category/benchmark.py",
    "merchant/benchmark.py",
    "intent/benchmark.py",
    "recurring/benchmark.py",
    "income/benchmark.py",
    # Phase 3+:
    # "embedding/benchmark.py",
    # "anomaly/benchmark.py",
    # Phase 5+:
    # "link_prediction/benchmark.py",
]


def run_benchmarks(dataset_path: str, output_dir: str) -> dict:
    """Run all benchmarks and collect results."""
    results = {
        "benchmark_date": datetime.utcnow().isoformat() + "Z",
        "dataset": dataset_path,
        "dataset_size": 0,
        "models": {}
    }

    # Count dataset size
    if Path(dataset_path).exists():
        with open(dataset_path) as f:
            results["dataset_size"] = sum(1 for _ in f)

    # Run each benchmark
    for script in BENCHMARK_SCRIPTS:
        script_path = Path(script)
        if not script_path.exists():
            print(f"⊘ {script}: not found (stub - Phase 2+)")
            continue

        print(f"→ Running {script}...", file=sys.stderr)
        try:
            # TODO: Invoke benchmark.py
            # For now, stub
            results["models"][script_path.parent.name] = {
                "version": "0.1.0",
                "status": "planned",
                "note": "Implementation deferred to Phase 2"
            }
        except Exception as e:
            print(f"✗ {script}: {e}", file=sys.stderr)

    return results


def main():
    parser = argparse.ArgumentParser(
        description="Run all model benchmarks"
    )
    parser.add_argument(
        "--dataset",
        required=True,
        help="Golden dataset path (JSONL)"
    )
    parser.add_argument(
        "--output",
        default="reports/benchmark.json",
        help="Output JSON report"
    )

    args = parser.parse_args()

    results = run_benchmarks(args.dataset, Path(args.output).parent)

    # Write report
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, "w") as f:
        json.dump(results, f, indent=2)

    print(f"✓ Report written to {output_path}", file=sys.stderr)
    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
