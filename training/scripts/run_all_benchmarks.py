#!/usr/bin/env python3
"""
Master benchmark runner for FinanceOS Intelligence models.

Runs all model benchmarks and aggregates results into single JSON report.
"""

import sys
import subprocess
import json
from pathlib import Path
from datetime import datetime

BENCHMARKS = [
    ("Category", "training/category/benchmark.py"),
    ("Merchant", "training/merchant/benchmark.py"),
    ("Intent", "training/intent/benchmark.py"),
    ("Recurring", "training/recurring/benchmark.py"),
]

def run_benchmark(name: str, script_path: str) -> tuple[bool, dict]:
    """Run a single benchmark script."""
    print(f"\n{'='*60}")
    print(f"Running {name} Benchmark")
    print(f"{'='*60}")

    try:
        result = subprocess.run([sys.executable, script_path], cwd="/Users/pragoel/Documents/GitHub/FinanceOS", 
                                capture_output=True, text=True, timeout=60)
        print(result.stdout)
        if result.stderr:
            print(f"STDERR: {result.stderr}")

        success = result.returncode == 0

        # Try to load the generated report
        report_name = script_path.split("/")[-2]
        report_path = Path(f"/Users/pragoel/Documents/GitHub/FinanceOS/training/reports/{report_name}_benchmark.json")
        
        report_data = {}
        if report_path.exists():
            with open(report_path) as f:
                report_data = json.load(f)

        return success, report_data

    except subprocess.TimeoutExpired:
        print(f"✗ {name} benchmark timed out")
        return False, {}
    except Exception as e:
        print(f"✗ {name} benchmark failed: {e}")
        return False, {}

def main():
    """Run all benchmarks and generate aggregated report."""
    results = {}
    all_passed = True

    for name, script in BENCHMARKS:
        passed, report = run_benchmark(name, script)
        results[name] = {"passed": passed, "report": report}
        if not passed:
            all_passed = False

    # Generate summary report
    summary = {
        "benchmark_date": datetime.utcnow().isoformat() + "Z",
        "dataset": "golden_v1",
        "total_benchmarks": len(BENCHMARKS),
        "passed": sum(1 for r in results.values() if r["passed"]),
        "failed": sum(1 for r in results.values() if not r["passed"]),
        "results": results,
        "overall_passed": all_passed,
    }

    # Write summary
    report_dir = Path("/Users/pragoel/Documents/GitHub/FinanceOS/training/reports")
    report_dir.mkdir(parents=True, exist_ok=True)

    summary_path = report_dir / "benchmark_summary.json"
    with open(summary_path, "w") as f:
        json.dump(summary, f, indent=2)

    print(f"\n{'='*60}")
    print(f"Benchmark Summary")
    print(f"{'='*60}")
    print(f"Total: {summary['total_benchmarks']} | Passed: {summary['passed']} | Failed: {summary['failed']}")
    print(f"Overall: {'✓ PASSED' if all_passed else '✗ FAILED'}")
    print(f"\nReport: {summary_path}")

    return 0 if all_passed else 1

if __name__ == "__main__":
    sys.exit(main())
