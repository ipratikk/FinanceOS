#!/usr/bin/env python3
"""
Creates the updatable CoreML kNN model and vocabulary for on-device personalization.

Run from repo root:
    python3 Scripts/create_knn_model.py

Outputs (relative to repo root):
    Packages/FinanceIntelligence/Sources/FinanceIntelligence/Resources/TransactionKNNClassifier.mlmodel
    Packages/FinanceIntelligence/Sources/FinanceIntelligence/Resources/transaction_vocab.json

Requires:
    pip install coremltools
"""

import csv
import json
import re
import sys
from collections import Counter
from pathlib import Path

try:
    import coremltools as ct
    from coremltools.models.nearest_neighbors import KNearestNeighborsClassifierBuilder
except ImportError:
    print("Error: coremltools not installed. Run: pip install coremltools")
    sys.exit(1)

VOCAB_SIZE = 200
K = 5
REPO_ROOT = Path(__file__).parent.parent
RESOURCES = REPO_ROOT / "Packages/FinanceIntelligence/Sources/FinanceIntelligence/Resources"
TRAINING_CSV = REPO_ROOT / "Resources/hdfc_text_classifier.csv"


def tokenize(text: str) -> list[str]:
    text = re.sub(r"\s*#?\d{4,}\s*", " ", text.lower())
    return [w for w in re.split(r"[^a-z0-9]+", text) if len(w) >= 2]


def build_vocab(csv_path: Path) -> list[str]:
    counts = Counter()
    with open(csv_path) as f:
        for row in csv.DictReader(f):
            counts.update(tokenize(row["text"]))
    return [word for word, _ in counts.most_common(VOCAB_SIZE)]


def create_knn_model(vocab: list[str]) -> None:
    builder = KNearestNeighborsClassifierBuilder(
        input_name="features",
        output_name="label",
        number_of_dimensions=len(vocab),
        default_class_label="transfers",
        number_of_neighbors=K,
        weighting_scheme="inverse_distance",
        index_type="linear",
    )
    builder.spec.isUpdatable = True

    model = ct.models.MLModel(builder.spec)
    out_path = RESOURCES / "TransactionKNNClassifier.mlmodel"
    model.save(str(out_path))
    print(f"Saved: {out_path}")

    vocab_path = RESOURCES / "transaction_vocab.json"
    vocab_path.write_text(json.dumps(vocab))
    print(f"Saved: {vocab_path} ({len(vocab)} tokens)")


if __name__ == "__main__":
    if not TRAINING_CSV.exists():
        print(f"Error: training CSV not found at {TRAINING_CSV}")
        sys.exit(1)

    print(f"Building vocabulary from {TRAINING_CSV}...")
    vocab = build_vocab(TRAINING_CSV)
    print(f"Top 10 tokens: {vocab[:10]}")

    print("Creating updatable kNN model...")
    create_knn_model(vocab)
    print("Done. Place the model files in the Xcode bundle and build.")
