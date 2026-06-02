#!/usr/bin/env python3
"""
Benchmark IntentClassifier (Model 3) against golden dataset.

Metrics: Macro F1, Weighted F1, per-class recall (emphasize salary/payment).

Usage:
  python intent/benchmark.py \\
    --model artifacts/IntentClassifier_v0.1.mlpackage \\
    --dataset data/golden_transactions.jsonl
"""

import argparse
import json
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description="Benchmark Intent Classifier")
    parser.add_argument("--model", required=True, help="Model path")
    parser.add_argument("--dataset", required=True, help="Golden dataset JSONL")
    parser.add_argument("--output", default="reports/intent_benchmark.json")

    args = parser.parse_args()

    # TODO: Phase 3 implementation
    result = {
        "model": args.model,
        "dataset": args.dataset,
        "status": "planned",
        "note": "Implementation in Phase 3 (behavioral intelligence)"
    }

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w") as f:
        json.dump(result, f, indent=2)

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
