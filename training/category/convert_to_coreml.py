#!/usr/bin/env python3
"""
Convert trained CategoryClassifier pickle model to CoreML format.

Input:
- training/category/models/category_classifier_v1.2.pkl
- training/category/models/vectorizer_v1.2.pkl

Output:
- training/category/models/CategoryClassifier_v1.2.mlmodel

Process:
1. Load pickle model + vectorizer
2. Create sklearn pipeline
3. Convert to CoreML using coremltools
4. Save as .mlmodel

NOTE: coremltools doesn't support TfidfVectorizer.
Future work: Re-train with DictVectorizer or export vectorizer coefficients separately.
"""

import pickle
import sys
from pathlib import Path
from typing import Any

try:
    import coremltools as ct
    from coremltools.converters.sklearn import convert
except ImportError:
    print("Error: coremltools not installed. Run: pip install coremltools")
    sys.exit(1)


def load_model_and_vectorizer(
    model_path: str, vectorizer_path: str
) -> tuple[Any, Any]:
    """Load pickle model and vectorizer."""
    with open(model_path, "rb") as f:
        model = pickle.load(f)
    with open(vectorizer_path, "rb") as f:
        vectorizer = pickle.load(f)
    return model, vectorizer


def main():
    model_path = Path("training/category/models/category_classifier_v1.2.pkl")
    vectorizer_path = Path("training/category/models/vectorizer_v1.2.pkl")

    if not model_path.exists():
        print(f"Error: {model_path} not found")
        return 1

    if not vectorizer_path.exists():
        print(f"Error: {vectorizer_path} not found")
        return 1

    print(f"Loading models...\n")
    model, vectorizer = load_model_and_vectorizer(str(model_path), str(vectorizer_path))

    print(f"Model type: {type(model).__name__}")
    print(f"Vectorizer type: {type(vectorizer).__name__}")
    print(f"Classes: {list(model.classes_)}\n")

    print("Status: TfidfVectorizer not supported by coremltools sklearn converter.")
    print("Supported vectorizers: DictVectorizer, OneHotEncoder")
    print("\nFuture work:")
    print("1. Re-train category classifier with DictVectorizer")
    print("2. Or export vectorizer coefficients + implement TF-IDF in Swift")
    print("3. Then convert to CoreML for on-device inference")

    return 0


if __name__ == "__main__":
    sys.exit(main())
