#!/usr/bin/env python3
"""
Train IntentClassifier v0.1 on 50K intent examples.

Input: intent_training_raw.csv (50K labeled transactions)
Output: intent_classifier_v0.1.pkl, vectorizer_intent_v0.1.pkl

Architecture:
- Vectorizer: TfidfVectorizer (5000 features, unigrams + bigrams)
- Classifier: LogisticRegression (balanced class weights, max_iter=1000)
- Train/test split: 80/20 stratified

Acceptance criteria:
- Macro F1 >= 0.95
- Weighted F1 >= 0.96
- Critical class recall: salary >= 0.98, credit_card_payment >= 0.95
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
    from sklearn.metrics import accuracy_score, f1_score, precision_score, recall_score
except ImportError:
    print("Error: scikit-learn not installed")
    sys.exit(1)


def load_training_data(path: str) -> Tuple[List[str], List[str]]:
    """Load training data from CSV."""
    narrations = []
    intents = []
    with open(path) as f:
        reader = csv.DictReader(f)
        for row in reader:
            narrations.append(row["narration"])
            intents.append(row["intent"])
    return narrations, intents


def main():
    input_path = Path("training/intent/intent_training_raw.csv")
    output_dir = Path("training/intent/models")

    if not input_path.exists():
        print(f"Error: {input_path} not found")
        return 1

    print(f"Loading training data from {input_path}...")
    narrations, intents = load_training_data(str(input_path))
    print(f"✓ Loaded {len(narrations)} examples\n")

    print(f"Dataset: {len(narrations)} examples, {len(set(intents))} intent classes")
    X_train, X_test, y_train, y_test = train_test_split(
        narrations, intents, test_size=0.2, random_state=42, stratify=intents
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
    y_test_arr = np.array(y_test)

    accuracy = accuracy_score(y_test, y_pred)
    macro_f1 = f1_score(y_test, y_pred, average="macro", zero_division=0)
    weighted_f1 = f1_score(y_test, y_pred, average="weighted", zero_division=0)
    macro_precision = precision_score(y_test, y_pred, average="macro", zero_division=0)
    macro_recall = recall_score(y_test, y_pred, average="macro", zero_division=0)

    print(f"Accuracy: {accuracy:.4f}")
    print(f"Macro F1: {macro_f1:.4f}")
    print(f"Weighted F1: {weighted_f1:.4f}")
    print(f"Macro Precision: {macro_precision:.4f}")
    print(f"Macro Recall: {macro_recall:.4f}\n")

    print("Critical class recall:")
    critical_classes = ["salary", "credit_card_payment"]
    critical_passes = True
    for cls in critical_classes:
        if cls in classifier.classes_:
            class_recall = recall_score(y_test, y_pred, labels=[cls], average="micro", zero_division=0)
            threshold = 0.98 if cls == "salary" else 0.95
            status = "✓" if class_recall >= threshold else "✗"
            print(f"  {cls}: {class_recall:.4f} (target >= {threshold}) {status}")
            if class_recall < threshold:
                critical_passes = False
    print()

    macro_f1_pass = macro_f1 >= 0.95
    weighted_f1_pass = weighted_f1 >= 0.96

    if macro_f1_pass and weighted_f1_pass:
        print(f"✓ PASSED: Macro F1 >= 0.95 and Weighted F1 >= 0.96")
    else:
        if not macro_f1_pass:
            print(f"✗ FAILED: Macro F1 {macro_f1:.4f} < 0.95")
        if not weighted_f1_pass:
            print(f"✗ FAILED: Weighted F1 {weighted_f1:.4f} < 0.96")

    output_dir.mkdir(parents=True, exist_ok=True)
    classifier_path = output_dir / "intent_classifier_v0.1.pkl"
    vectorizer_path = output_dir / "vectorizer_intent_v0.1.pkl"

    with open(classifier_path, "wb") as f:
        pickle.dump(classifier, f)
    with open(vectorizer_path, "wb") as f:
        pickle.dump(vectorizer, f)

    print(f"\n✓ Model saved: {classifier_path}")
    print(f"✓ Vectorizer saved: {vectorizer_path}")

    print(f"\n{'=' * 60}")
    print(f"IntentClassifier v0.1 Training Summary")
    print(f"{'=' * 60}")
    print(f"Dataset: {len(narrations)} examples")
    print(f"Intent classes: {len(set(intents))}")
    print(f"Macro F1: {macro_f1:.4f} (target: >= 0.95)")
    print(f"Weighted F1: {weighted_f1:.4f} (target: >= 0.96)")
    print(f"Status: {'✓ PASSED' if (macro_f1_pass and weighted_f1_pass) else '✗ FAILED'}")
    print(f"{'=' * 60}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
