#!/usr/bin/env python3
"""
Train MerchantRecognizer v0.1 on merchant training dataset.

Target: Top-1 Accuracy >= 0.95 on 100K stratified examples.

Process:
1. Load merchant_training_raw.csv (100K examples)
2. Split: 80% train, 20% test
3. Vectorize: TF-IDF on narration text
4. Train: LogisticRegression with balanced class weights
5. Evaluate: Accuracy metrics on test set
6. Report: Save model + metrics JSON

Output:
- models/merchant_recognizer_v0.1.pkl (trained model)
- reports/merchant_training_metrics.json (evaluation report)
"""

import csv
import json
import pickle
from pathlib import Path
from typing import Dict, Any, Tuple, List
from datetime import datetime, timezone

from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    f1_score,
    precision_score,
    recall_score,
    confusion_matrix,
    classification_report,
)
import numpy as np


def load_training_data(csv_path: str) -> Tuple[List[str], List[str]]:
    """Load narration and merchant labels from CSV."""
    narrations = []
    merchants = []

    with open(csv_path, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            narration = row.get("narration", "").strip()
            merchant = row.get("merchant", "").strip()
            if narration and merchant:
                narrations.append(narration)
                merchants.append(merchant)

    return narrations, merchants


def train_recognizer(
    narrations: List[str],
    merchants: List[str],
    test_size: float = 0.2,
    random_state: int = 42
) -> Tuple[TfidfVectorizer, LogisticRegression, Dict[str, Any]]:
    """Train merchant recognizer on narration/merchant data."""
    print(f"Dataset: {len(narrations)} examples, {len(set(merchants))} merchants")

    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        narrations, merchants, test_size=test_size, random_state=random_state, stratify=merchants
    )
    print(f"Train: {len(X_train)}, Test: {len(X_test)}")

    # Vectorize
    print("\nVectorizing narrations (TF-IDF)...")
    vectorizer = TfidfVectorizer(
        max_features=5000,
        ngram_range=(1, 2),
        min_df=2,
        max_df=0.95,
        lowercase=True,
        stop_words="english",
    )
    X_train_vec = vectorizer.fit_transform(X_train)
    X_test_vec = vectorizer.transform(X_test)
    print(f"✓ Vectorized: {X_train_vec.shape[1]} features")

    # Train recognizer
    print("\nTraining LogisticRegression (balanced)...")
    clf = LogisticRegression(
        max_iter=1000,
        class_weight="balanced",
        solver="lbfgs",
        random_state=random_state,
        n_jobs=-1,
    )
    clf.fit(X_train_vec, y_train)
    print("✓ Model trained")

    # Evaluate
    print("\nEvaluating on test set...")
    y_pred = clf.predict(X_test_vec)

    accuracy = float(accuracy_score(y_test, y_pred))
    macro_f1 = float(f1_score(y_test, y_pred, average="macro"))
    weighted_f1 = float(f1_score(y_test, y_pred, average="weighted"))

    metrics = {
        "accuracy": accuracy,
        "macro_f1": macro_f1,
        "weighted_f1": weighted_f1,
        "macro_precision": float(precision_score(y_test, y_pred, average="macro")),
        "macro_recall": float(recall_score(y_test, y_pred, average="macro")),
    }

    # Per-class metrics
    per_class = {}
    y_test_arr = np.array(y_test)

    precisions = precision_score(y_test, y_pred, average=None, labels=sorted(set(y_test)), zero_division=0)
    recalls = recall_score(y_test, y_pred, average=None, labels=sorted(set(y_test)), zero_division=0)
    f1s = f1_score(y_test, y_pred, average=None, labels=sorted(set(y_test)), zero_division=0)

    for i, merchant in enumerate(sorted(set(y_test))):
        mask = y_test_arr == merchant
        per_class[merchant] = {
            "precision": float(precisions[i]),
            "recall": float(recalls[i]),
            "f1": float(f1s[i]),
            "support": int(mask.sum()),
        }

    metrics["per_class"] = per_class

    print(f"Accuracy: {metrics['accuracy']:.4f}")
    print(f"Macro F1: {metrics['macro_f1']:.4f}")
    print(f"Weighted F1: {metrics['weighted_f1']:.4f}")
    print(f"Macro Precision: {metrics['macro_precision']:.4f}")
    print(f"Macro Recall: {metrics['macro_recall']:.4f}")

    # Check acceptance criteria
    if accuracy >= 0.95:
        print("\n✓ PASSED: Accuracy >= 0.95")
    else:
        print(f"\n✗ FAILED: Accuracy {accuracy:.4f} < 0.95")

    return vectorizer, clf, metrics


def main():
    # Paths
    data_path = Path("training/data/merchant_training_raw.csv")
    model_path = Path("training/merchant/models/merchant_recognizer_v0.1.pkl")
    vectorizer_path = Path("training/merchant/models/vectorizer_merchant_v0.1.pkl")
    report_path = Path("training/reports/merchant_training_metrics.json")

    if not data_path.exists():
        print(f"Error: {data_path} not found")
        return 1

    print(f"Loading training data from {data_path}...\n")
    narrations, merchants = load_training_data(str(data_path))

    print(f"Training MerchantRecognizer v0.1...")
    vectorizer, clf, metrics = train_recognizer(narrations, merchants)

    # Save model
    model_path.parent.mkdir(parents=True, exist_ok=True)
    with open(model_path, "wb") as f:
        pickle.dump(clf, f)
    print(f"\n✓ Model saved: {model_path}")

    with open(vectorizer_path, "wb") as f:
        pickle.dump(vectorizer, f)
    print(f"✓ Vectorizer saved: {vectorizer_path}")

    # Save report
    report = {
        "model_name": "MerchantRecognizer",
        "model_version": "v0.1",
        "training_date": datetime.now(timezone.utc).isoformat(),
        "dataset": "merchant_training_raw.csv",
        "dataset_size": len(narrations),
        "num_merchants": len(set(merchants)),
        "metrics": metrics,
        "vectorizer": {
            "type": "TfidfVectorizer",
            "max_features": 5000,
            "ngram_range": (1, 2),
        },
        "classifier": {
            "type": "LogisticRegression",
            "class_weight": "balanced",
            "max_iter": 1000,
        },
        "acceptance_criteria": {
            "top1_accuracy_target": 0.95,
            "top1_accuracy_achieved": metrics["accuracy"],
            "passed": metrics["accuracy"] >= 0.95,
        },
    }

    report_path.parent.mkdir(parents=True, exist_ok=True)
    with open(report_path, "w") as f:
        json.dump(report, f, indent=2)
    print(f"✓ Report saved: {report_path}")

    # Summary
    print(f"\n{'=' * 60}")
    print(f"MerchantRecognizer v0.1 Training Summary")
    print(f"{'=' * 60}")
    print(f"Dataset: {len(narrations)} examples")
    print(f"Merchants: {len(set(merchants))}")
    print(f"Accuracy: {metrics['accuracy']:.4f} (target: >= 0.95)")
    print(f"Status: {'✓ PASSED' if metrics['accuracy'] >= 0.95 else '✗ FAILED'}")
    print(f"{'=' * 60}")

    return 0 if metrics["accuracy"] >= 0.95 else 1


if __name__ == "__main__":
    import sys
    sys.exit(main())
