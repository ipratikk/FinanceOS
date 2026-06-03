#!/usr/bin/env python3
"""
Train IncomeClassifier v0.1 on 50K binary income examples (Model 6).

Input: income_training_raw.csv (50K binary labeled transactions)
Output: income_classifier_v0.1.pkl, vectorizer_income_v0.1.pkl

Architecture:
- Vectorizer: TfidfVectorizer (5000 features, unigrams + bigrams)
- Classifier: LogisticRegression (balanced class weights)
- Train/test split: 80/20 stratified

Binary classification: income (1) vs. non-income (0)

Acceptance criteria:
- Binary precision >= 0.93
- Salary recall >= 0.97 (income subset)
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
    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.linear_model import LogisticRegression
    from sklearn.metrics import (
        accuracy_score, f1_score, precision_score, recall_score,
        confusion_matrix, roc_auc_score, roc_curve
    )
except ImportError:
    print("Error: scikit-learn not installed")
    sys.exit(1)


def load_training_data(path: str) -> Tuple[List[str], List[int]]:
    """Load training data from CSV."""
    narrations = []
    labels = []
    with open(path) as f:
        reader = csv.DictReader(f)
        for row in reader:
            narrations.append(row["narration"])
            labels.append(int(row["is_income"]))
    return narrations, labels


def main():
    input_path = Path("training/income/income_training_raw.csv")
    output_dir = Path("training/income/models")

    if not input_path.exists():
        print(f"Error: {input_path} not found")
        return 1

    print(f"Loading training data from {input_path}...")
    narrations, labels = load_training_data(str(input_path))
    print(f"✓ Loaded {len(narrations)} examples\n")

    income_count = sum(labels)
    non_income_count = len(labels) - income_count
    print(f"Dataset: {len(narrations)} examples")
    print(f"  Income: {income_count} ({100*income_count/len(labels):.2f}%)")
    print(f"  Non-income: {non_income_count} ({100*non_income_count/len(labels):.2f}%)\n")

    X_train, X_test, y_train, y_test = train_test_split(
        narrations, labels, test_size=0.2, random_state=42, stratify=labels
    )
    print(f"Train: {len(X_train)}, Test: {len(X_test)}\n")

    print("Vectorizing narrations (TF-IDF)...")
    vectorizer = TfidfVectorizer(
        max_features=5000,
        ngram_range=(1, 2),
        min_df=2,
        max_df=0.95,
        stop_words="english",
    )
    X_train_vec = vectorizer.fit_transform(X_train)
    X_test_vec = vectorizer.transform(X_test)
    print(f"✓ Vectorized: 5000 features\n")

    print("Training LogisticRegression (balanced)...")
    classifier = LogisticRegression(
        max_iter=1000, class_weight="balanced", random_state=42, n_jobs=-1
    )
    classifier.fit(X_train_vec, y_train)
    print("✓ Model trained\n")

    print("Evaluating on test set...")
    y_pred = classifier.predict(X_test_vec)
    y_pred_proba = classifier.predict_proba(X_test_vec)[:, 1]

    accuracy = accuracy_score(y_test, y_pred)
    precision = precision_score(y_test, y_pred, zero_division=0)
    recall = recall_score(y_test, y_pred, zero_division=0)
    f1 = f1_score(y_test, y_pred, zero_division=0)
    auc_roc = roc_auc_score(y_test, y_pred_proba)

    print(f"Accuracy: {accuracy:.4f}")
    print(f"Precision (income): {precision:.4f}")
    print(f"Recall (income): {recall:.4f}")
    print(f"F1 Score: {f1:.4f}")
    print(f"ROC-AUC: {auc_roc:.4f}\n")

    # Confusion matrix
    tn, fp, fn, tp = confusion_matrix(y_test, y_pred).ravel()
    print(f"Confusion Matrix:")
    print(f"  TP (income detected): {tp}")
    print(f"  FP (false income): {fp}")
    print(f"  TN (non-income correct): {tn}")
    print(f"  FN (income missed): {fn}\n")

    # Check acceptance
    precision_pass = precision >= 0.93
    recall_pass = recall >= 0.97

    if precision_pass and recall_pass:
        print(f"✓ PASSED: Precision >= 0.93 and Recall >= 0.97")
    else:
        if not precision_pass:
            print(f"✗ FAILED: Precision {precision:.4f} < 0.93")
        if not recall_pass:
            print(f"✗ FAILED: Recall {recall:.4f} < 0.97")

    output_dir.mkdir(parents=True, exist_ok=True)
    classifier_path = output_dir / "income_classifier_v0.1.pkl"
    vectorizer_path = output_dir / "vectorizer_income_v0.1.pkl"

    with open(classifier_path, "wb") as f:
        pickle.dump(classifier, f)
    with open(vectorizer_path, "wb") as f:
        pickle.dump(vectorizer, f)

    print(f"\n✓ Model saved: {classifier_path}")
    print(f"✓ Vectorizer saved: {vectorizer_path}")

    print(f"\n{'=' * 60}")
    print(f"IncomeClassifier v0.1 Training Summary")
    print(f"{'=' * 60}")
    print(f"Dataset: {len(narrations)} examples (binary)")
    print(f"Income class: {income_count} ({100*income_count/len(labels):.2f}%)")
    print(f"Precision (income): {precision:.4f} (target: >= 0.93)")
    print(f"Recall (income): {recall:.4f} (target: >= 0.97)")
    print(f"F1 Score: {f1:.4f}")
    print(f"ROC-AUC: {auc_roc:.4f}")
    print(f"Status: {'✓ PASSED' if (precision_pass and recall_pass) else '✗ FAILED'}")
    print(f"{'=' * 60}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
