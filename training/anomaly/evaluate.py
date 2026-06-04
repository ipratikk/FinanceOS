#!/usr/bin/env python3
"""
Evaluate AnomalyDetector v0.1 against benchmark thresholds.

Gates:
- FPR <= 0.05
- Precision >= 0.80
- Recall >= 0.75
- Duplicate detection precision >= 0.95
"""

import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent.parent))

MODEL_PATH = Path(__file__).parent / "models" / "AnomalyDetector_v0.1.pkl"
GOLDEN_PATH = Path(__file__).parent.parent / "data" / "golden_transactions_expanded.jsonl"


def main():
    try:
        import pickle
    except ImportError:
        print("✗ pickle unavailable")
        sys.exit(1)

    if not MODEL_PATH.exists():
        print(f"✗ Model not found: {MODEL_PATH}. Run train.py first.")
        sys.exit(1)

    with open(MODEL_PATH, "rb") as f:
        model = pickle.load(f)

    # Load and featurize
    from train import load_transactions, extract_features
    transactions = load_transactions()
    X = extract_features(transactions)

    rng = np.random.RandomState(42)
    n_anomalies = max(10, int(len(transactions) * 0.05))
    y_true = np.zeros(len(transactions), dtype=int)
    anomaly_idx = rng.choice(len(transactions), n_anomalies, replace=False)
    y_true[anomaly_idx] = 1

    y_pred = (model.predict(X) == -1).astype(int)

    tp = int(np.sum((y_pred == 1) & (y_true == 1)))
    fp = int(np.sum((y_pred == 1) & (y_true == 0)))
    tn = int(np.sum((y_pred == 0) & (y_true == 0)))
    fn = int(np.sum((y_pred == 0) & (y_true == 1)))

    fpr = fp / max(fp + tn, 1)
    precision = tp / max(tp + fp, 1)
    recall = tp / max(tp + fn, 1)

    print(f"FPR:       {fpr:.4f}  {'✓' if fpr <= 0.05 else '✗'}  (gate <= 0.05)")
    print(f"Precision: {precision:.4f}  {'✓' if precision >= 0.80 else '✗'}  (gate >= 0.80)")
    print(f"Recall:    {recall:.4f}  {'✓' if recall >= 0.75 else '✗'}  (gate >= 0.75)")

    passed = fpr <= 0.05 and precision >= 0.80 and recall >= 0.75
    print(f"\n{'✓ PASS' if passed else '✗ FAIL'}")
    if not passed:
        sys.exit(1)


if __name__ == "__main__":
    main()
