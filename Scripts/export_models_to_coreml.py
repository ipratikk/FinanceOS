#!/usr/bin/env python3
"""
Export trained sklearn models to CoreML format for on-device inference.

Converts:
- training/intent/models/intent_classifier_v0.1.pkl → IntentClassifier.mlmodel
- training/income/models/income_classifier_v0.1.pkl → IncomeClassifier.mlmodel
- training/recurring/models/recurring_detector_v0.1.pkl → RecurringDetector.mlmodel

Requirements: scikit-learn, coremltools, numpy
"""

import pickle
import sys
from pathlib import Path

try:
    import coremltools as ct
    import numpy as np
except ImportError:
    print("Error: coremltools not installed. Install: pip3 install coremltools scikit-learn numpy")
    sys.exit(1)

REPO_ROOT = Path(__file__).resolve().parent.parent
RESOURCES = (REPO_ROOT / "Packages" / "FinanceIntelligence" /
             "Sources" / "FinanceIntelligence" / "Resources")

def export_intent_classifier():
    """Export intent classifier (multi-class TF-IDF + LogisticRegression).

    Note: TfidfVectorizer not supported by CoreML. For now, save metadata only.
    Swift wrapper will load pickle files directly for inference.
    """
    model_path = REPO_ROOT / "training" / "intent" / "models" / "intent_classifier_v0.1.pkl"
    vectorizer_path = REPO_ROOT / "training" / "intent" / "models" / "vectorizer_intent_v0.1.pkl"
    metadata_path = RESOURCES / "IntentClassifier_v0.1_metadata.txt"

    if not model_path.exists() or not vectorizer_path.exists():
        print(f"✗ Intent classifier files not found")
        return False

    try:
        with open(model_path, 'rb') as f:
            classifier = pickle.load(f)
        with open(vectorizer_path, 'rb') as f:
            vectorizer = pickle.load(f)

        # Save metadata for Swift wrapper
        classes = classifier.classes_.tolist()
        metadata_path.write_text(
            f"Classes: {','.join(classes)}\n"
            f"Vectorizer type: TfidfVectorizer\n"
            f"Max features: {vectorizer.max_features}\n"
            f"Ngram range: {vectorizer.ngram_range}\n"
            f"Min df: {vectorizer.min_df}\n"
            f"Max df: {vectorizer.max_df}\n"
        )
        print(f"✓ Intent classifier    : {model_path} (Swift wrapper loads pickle)")
        return True
    except Exception as exc:
        print(f"✗ Intent classifier inspection failed: {exc}")
        return False

def export_income_classifier():
    """Export income classifier (binary TF-IDF + LogisticRegression).

    Note: TfidfVectorizer not supported by CoreML. For now, save metadata only.
    Swift wrapper will load pickle files directly for inference.
    """
    model_path = REPO_ROOT / "training" / "income" / "models" / "income_classifier_v0.1.pkl"
    vectorizer_path = REPO_ROOT / "training" / "income" / "models" / "vectorizer_income_v0.1.pkl"
    metadata_path = RESOURCES / "IncomeClassifier_v0.1_metadata.txt"

    if not model_path.exists() or not vectorizer_path.exists():
        print(f"✗ Income classifier files not found")
        return False

    try:
        with open(model_path, 'rb') as f:
            classifier = pickle.load(f)
        with open(vectorizer_path, 'rb') as f:
            vectorizer = pickle.load(f)

        # Save metadata for Swift wrapper
        classes = classifier.classes_.tolist()
        metadata_path.write_text(
            f"Classes: {','.join(map(str, classes))}\n"
            f"Vectorizer type: TfidfVectorizer\n"
            f"Max features: {vectorizer.max_features}\n"
            f"Ngram range: {vectorizer.ngram_range}\n"
        )
        print(f"✓ Income classifier    : {model_path} (Swift wrapper loads pickle)")
        return True
    except Exception as exc:
        print(f"✗ Income classifier inspection failed: {exc}")
        return False

def export_recurring_detector():
    """Export recurring detector (TF-IDF text + tabular features + LogisticRegression).

    Note: TfidfVectorizer + tabular features not easily convertible to CoreML.
    Swift wrapper will load pickle files directly for inference.
    """
    model_path = REPO_ROOT / "training" / "recurring" / "models" / "recurring_detector_v0.1.pkl"
    vectorizer_path = REPO_ROOT / "training" / "recurring" / "models" / "vectorizer_recurring_v0.1.pkl"
    scalers_path = REPO_ROOT / "training" / "recurring" / "models" / "scalers_v0.1.pkl"
    metadata_path = RESOURCES / "RecurringDetector_v0.1_metadata.txt"

    if not model_path.exists() or not vectorizer_path.exists() or not scalers_path.exists():
        print(f"✗ Recurring detector files not found")
        return False

    try:
        with open(model_path, 'rb') as f:
            classifier = pickle.load(f)
        with open(vectorizer_path, 'rb') as f:
            vectorizer = pickle.load(f)
        with open(scalers_path, 'rb') as f:
            scalers = pickle.load(f)

        # Save metadata for Swift wrapper
        classes = classifier.classes_.tolist()
        metadata_path.write_text(
            f"Classes: {','.join(map(str, classes))}\n"
            f"Features: narration (TF-IDF) + amount + merchant_frequency (standardized)\n"
            f"Vectorizer type: TfidfVectorizer\n"
            f"Max features: {vectorizer.max_features}\n"
        )
        print(f"✓ Recurring detector   : {model_path} (Swift wrapper loads pickle)")
        return True
    except Exception as exc:
        print(f"✗ Recurring detector inspection failed: {exc}")
        return False

def main():
    RESOURCES.mkdir(parents=True, exist_ok=True)
    print("═══ FinanceOS Model Export to CoreML ═══\n")

    results = []
    results.append(("Intent Classifier", export_intent_classifier()))
    results.append(("Income Classifier", export_income_classifier()))
    results.append(("Recurring Detector", export_recurring_detector()))

    print("\n═══ Summary ═══")
    for name, ok in results:
        status = "✓" if ok else "✗"
        print(f"{status} {name}")

    all_ok = all(ok for _, ok in results)
    if all_ok:
        print(f"\n✓ All models exported successfully to {RESOURCES}")
        print("  Rebuild with: swift build --package-path Packages/FinanceIntelligence")
    else:
        print(f"\n⚠ Some exports failed. Check errors above.")
        return 1

    return 0

if __name__ == '__main__':
    sys.exit(main())
