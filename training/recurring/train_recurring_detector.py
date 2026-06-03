#!/usr/bin/env python3
"""
Train RecurringDetector v0.1 on 50K tabular examples (Model 4).

Input: recurring_training_raw.csv (50K tabular labeled transactions)
Output: recurring_detector_v0.1.pkl

Architecture:
- Features: merchant_frequency, amount, narration (TF-IDF for merchant keywords)
- Classifier: LogisticRegression (balanced class weights)
- Train/test split: 80/20 stratified

Binary classification: recurring vs. one-time

Acceptance criteria:
- Binary precision >= 0.90
- Recall >= 0.88
- Monthly cadence F1 >= 0.90 (subset evaluation)
"""

import csv
import json
import pickle
import sys
from pathlib import Path
from typing import List, Tuple

try:
    import numpy as np
    from sklearn.model_selection import train_test_split
    from sklearn.preprocessing import StandardScaler
    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.linear_model import LogisticRegression
    from sklearn.metrics import accuracy_score, f1_score, precision_score, recall_score
except ImportError:
    print("Error: scikit-learn not installed")
    sys.exit(1)


def load_training_data(path: str) -> Tuple[List[str], List[int], List[dict]]:
    """Load training data from CSV."""
    narrations = []
    labels = []
    rows = []
    with open(path) as f:
        reader = csv.DictReader(f)
        for row in reader:
            narrations.append(row["narration"])
            labels.append(int(row["is_recurring"]))
            rows.append({
                "amount": float(row["amount"]),
                "merchant_frequency": int(row["merchant_frequency"]),
                "cadence": row["cadence"]
            })
    return narrations, labels, rows


def main():
    input_path = Path("training/recurring/recurring_training_raw.csv")
    output_dir = Path("training/recurring/models")

    if not input_path.exists():
        print(f"Error: {input_path} not found")
        return 1

    print(f"Loading training data from {input_path}...")
    narrations, labels, rows = load_training_data(str(input_path))
    print(f"✓ Loaded {len(narrations)} examples\n")

    recurring_count = sum(labels)
    non_recurring_count = len(labels) - recurring_count
    print(f"Dataset: {len(narrations)} examples")
    print(f"  Recurring: {recurring_count} ({100*recurring_count/len(labels):.2f}%)")
    print(f"  Non-recurring: {non_recurring_count} ({100*non_recurring_count/len(labels):.2f}%)\n")

    X_train, X_test, y_train, y_test = train_test_split(
        list(range(len(narrations))), labels, test_size=0.2, random_state=42, stratify=labels
    )
    print(f"Train: {len(X_train)}, Test: {len(X_test)}\n")

    # Vectorize narrations (for merchant keywords)
    print("Vectorizing narrations (TF-IDF)...")
    train_narrations = [narrations[i] for i in X_train]
    test_narrations = [narrations[i] for i in X_test]

    vectorizer = TfidfVectorizer(
        max_features=1000,
        ngram_range=(1, 2),
        min_df=2,
        max_df=0.95,
        stop_words="english",
    )
    X_train_text = vectorizer.fit_transform(train_narrations)
    X_test_text = vectorizer.transform(test_narrations)
    print(f"✓ Vectorized: 1000 text features")

    # Tabular features
    print("Extracting tabular features...")
    train_amounts = np.array([rows[i]["amount"] for i in X_train]).reshape(-1, 1)
    test_amounts = np.array([rows[i]["amount"] for i in X_test]).reshape(-1, 1)
    train_frequencies = np.array([rows[i]["merchant_frequency"] for i in X_train]).reshape(-1, 1)
    test_frequencies = np.array([rows[i]["merchant_frequency"] for i in X_test]).reshape(-1, 1)

    # Standardize tabular features
    scaler_amount = StandardScaler()
    scaler_freq = StandardScaler()
    train_amounts_scaled = scaler_amount.fit_transform(train_amounts)
    test_amounts_scaled = scaler_amount.transform(test_amounts)
    train_frequencies_scaled = scaler_freq.fit_transform(train_frequencies)
    test_frequencies_scaled = scaler_freq.transform(test_frequencies)

    # Combine text + tabular features
    X_train_combined = np.hstack([
        X_train_text.toarray(),
        train_amounts_scaled,
        train_frequencies_scaled
    ])
    X_test_combined = np.hstack([
        X_test_text.toarray(),
        test_amounts_scaled,
        test_frequencies_scaled
    ])
    print(f"✓ Combined features: {X_train_combined.shape[1]} total\n")

    print("Training LogisticRegression (balanced)...")
    classifier = LogisticRegression(
        max_iter=1000, class_weight="balanced", random_state=42, n_jobs=-1
    )
    classifier.fit(X_train_combined, y_train)
    print("✓ Model trained\n")

    print("Evaluating on test set...")
    y_pred = classifier.predict(X_test_combined)

    accuracy = accuracy_score(y_test, y_pred)
    precision = precision_score(y_test, y_pred, zero_division=0)
    recall = recall_score(y_test, y_pred, zero_division=0)
    f1 = f1_score(y_test, y_pred, zero_division=0)

    print(f"Accuracy: {accuracy:.4f}")
    print(f"Precision (recurring): {precision:.4f}")
    print(f"Recall (recurring): {recall:.4f}")
    print(f"F1 Score: {f1:.4f}\n")

    # Check acceptance
    precision_pass = precision >= 0.90
    recall_pass = recall >= 0.88

    if precision_pass and recall_pass:
        print(f"✓ PASSED: Precision >= 0.90 and Recall >= 0.88")
    else:
        if not precision_pass:
            print(f"✗ FAILED: Precision {precision:.4f} < 0.90")
        if not recall_pass:
            print(f"✗ FAILED: Recall {recall:.4f} < 0.88")

    # Evaluate monthly cadence (subset)
    y_test_monthly = [1 if rows[i]["cadence"] == "monthly" else 0 for i in X_test]
    if sum(y_test_monthly) > 0:
        monthly_mask = np.array(y_test_monthly) == 1
        y_pred_monthly = y_pred[monthly_mask]
        y_test_monthly_subset = np.array(y_test_monthly)[monthly_mask]
        if len(y_test_monthly_subset) > 0:
            monthly_f1 = f1_score(y_test_monthly_subset, y_pred_monthly, zero_division=0)
            print(f"Monthly cadence F1: {monthly_f1:.4f} (target >= 0.90)")

    output_dir.mkdir(parents=True, exist_ok=True)
    classifier_path = output_dir / "recurring_detector_v0.1.pkl"
    vectorizer_path = output_dir / "vectorizer_recurring_v0.1.pkl"
    scaler_path = output_dir / "scalers_v0.1.pkl"

    with open(classifier_path, "wb") as f:
        pickle.dump(classifier, f)
    with open(vectorizer_path, "wb") as f:
        pickle.dump(vectorizer, f)
    with open(scaler_path, "wb") as f:
        pickle.dump({"amount": scaler_amount, "frequency": scaler_freq}, f)

    print(f"\n✓ Model saved: {classifier_path}")
    print(f"✓ Vectorizer saved: {vectorizer_path}")
    print(f"✓ Scalers saved: {scaler_path}")

    print(f"\n{'=' * 60}")
    print(f"RecurringDetector v0.1 Training Summary")
    print(f"{'=' * 60}")
    print(f"Dataset: {len(narrations)} examples (tabular + text)")
    print(f"Features: 1000 text + 2 tabular (amount, merchant_frequency)")
    print(f"Precision (recurring): {precision:.4f} (target: >= 0.90)")
    print(f"Recall (recurring): {recall:.4f} (target: >= 0.88)")
    print(f"F1 Score: {f1:.4f}")
    print(f"Status: {'✓ PASSED' if (precision_pass and recall_pass) else '✗ FAILED'}")
    print(f"{'=' * 60}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
