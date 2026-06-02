#!/usr/bin/env python3
"""
Benchmark CategoryClassifier (Model 2) against golden dataset.

Metrics: Macro F1, Weighted F1, per-class precision/recall, confusion matrix.

Usage:
  python category/benchmark.py \\
    --model artifacts/CategoryClassifier_v1.2.mlpackage \\
    --dataset data/golden_transactions.jsonl
"""

import argparse
import json
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description="Benchmark Category Classifier")
    parser.add_argument("--model", required=True, help="Model path")
    parser.add_argument("--dataset", required=True, help="Golden dataset JSONL")
    parser.add_argument("--output", default="reports/category_benchmark.json")

    args = parser.parse_args()

    # TODO: Phase 2 implementation
    # For Phase 1: stub
    result = {
        "model": args.model,
        "dataset": args.dataset,
        "status": "planned",
        "note": "Implementation in Phase 2 (model training)"
    }

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w") as f:
        json.dump(result, f, indent=2)

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
