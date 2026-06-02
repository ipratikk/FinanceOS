#!/usr/bin/env python3
"""
Benchmark MerchantRecognizer (Model 1) against golden dataset.

Metrics: Top-1/Top-3 accuracy, per-merchant precision/recall.

Usage:
  python merchant/benchmark.py \\
    --model artifacts/MerchantRecognizer_v0.1.mlpackage \\
    --dataset data/golden_transactions.jsonl
"""

import argparse
import json
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description="Benchmark Merchant Recognizer")
    parser.add_argument("--model", required=True, help="Model path")
    parser.add_argument("--dataset", required=True, help="Golden dataset JSONL")
    parser.add_argument("--output", default="reports/merchant_benchmark.json")

    args = parser.parse_args()

    # TODO: Phase 2 implementation
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
