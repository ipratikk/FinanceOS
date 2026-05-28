#!/usr/bin/env python3
"""
Train a Core ML transaction category classifier.

Usage:
    python train.py --data fixtures/sample_transactions.csv --output models/

Output:
    models/TransactionCategoryClassifier.mlpackage
    models/TransactionCategoryClassifier.metadata.json
    models/evaluation/category_metrics.json

NOTE: The sample fixture is a minimal anonymized dataset for pipeline validation only.
      It does NOT represent a production-quality model. Train on real anonymized data before shipping.
"""

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

import coremltools as ct
import numpy as np
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    f1_score,
    top_k_accuracy_score,
)
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import LabelEncoder


TAXONOMY_VERSION = "1.0.0"


def load_and_filter(path: str) -> pd.DataFrame:
    df = pd.read_csv(path)
    df = df[df["user_category"].notna()].copy()
    df = df[df["raw_description"].notna()].copy()
    df["raw_description"] = df["raw_description"].astype(str).str.strip()
    return df


def build_text_feature(df: pd.DataFrame) -> pd.Series:
    desc = df["raw_description"].str.lower()
    if "canonical_merchant" in df.columns:
        merchant = df["canonical_merchant"].fillna("").str.lower()
        return desc + " " + merchant
    return desc


def train(data_path: str, output_dir: str) -> None:
    output = Path(output_dir)
    output.mkdir(parents=True, exist_ok=True)
    (output / "evaluation").mkdir(exist_ok=True)

    print(f"Loading data from: {data_path}")
    df = load_and_filter(data_path)
    print(f"  Labeled rows: {len(df)}")

    text = build_text_feature(df)
    labels = df["user_category"].tolist()

    le = LabelEncoder()
    y = le.fit_transform(labels)
    classes = le.classes_.tolist()

    x_train, x_test, y_train, y_test = train_test_split(
        text.tolist(), y, test_size=0.2, random_state=42, stratify=y if len(df) >= 10 else None
    )

    pipeline = Pipeline([
        ("tfidf", TfidfVectorizer(max_features=5000, ngram_range=(1, 2), sublinear_tf=True)),
        ("clf", LogisticRegression(max_iter=1000, C=1.0, class_weight="balanced")),
    ])
    pipeline.fit(x_train, y_train)

    y_pred = pipeline.predict(x_test)
    acc = accuracy_score(y_test, y_pred)
    macro_f1 = f1_score(y_test, y_pred, average="macro", zero_division=0)

    proba = pipeline.predict_proba(x_test)
    try:
        top3_acc = top_k_accuracy_score(y_test, proba, k=3)
    except Exception:
        top3_acc = None

    report = classification_report(y_test, y_pred, target_names=classes, zero_division=0, output_dict=True)
    cm = confusion_matrix(y_test, y_pred).tolist()

    print(f"  Accuracy:  {acc:.4f}")
    print(f"  Macro F1:  {macro_f1:.4f}")
    if top3_acc:
        print(f"  Top-3 Acc: {top3_acc:.4f}")

    # Save evaluation metrics
    metrics = {
        "accuracy": acc,
        "macro_f1": macro_f1,
        "top3_accuracy": top3_acc,
        "confusion_matrix": cm,
        "class_names": classes,
        "per_class": {k: v for k, v in report.items() if isinstance(v, dict)},
        "evaluated_at": datetime.now(timezone.utc).isoformat(),
    }
    metrics_path = output / "evaluation" / "category_metrics.json"
    with open(metrics_path, "w") as f:
        json.dump(metrics, f, indent=2)
    print(f"  Metrics saved: {metrics_path}")

    # Export to Core ML
    mlmodel = export_to_coreml(pipeline, classes, acc, macro_f1)
    model_path = output / "TransactionCategoryClassifier.mlpackage"
    mlmodel.save(str(model_path))
    print(f"  Model saved: {model_path}")

    # Save metadata
    metadata = {
        "model_version": f"coreml-{datetime.now(timezone.utc).strftime('%Y%m%d')}",
        "taxonomy_version": TAXONOMY_VERSION,
        "trained_at": datetime.now(timezone.utc).isoformat(),
        "training_data_rows": len(df),
        "accuracy": acc,
        "macro_f1": macro_f1,
        "top3_accuracy": top3_acc,
        "notes": "Trained with scikit-learn LogisticRegression + TF-IDF. Export via coremltools.",
    }
    meta_path = output / "TransactionCategoryClassifier.metadata.json"
    with open(meta_path, "w") as f:
        json.dump(metadata, f, indent=2)
    print(f"  Metadata saved: {meta_path}")


def export_to_coreml(pipeline: Pipeline, classes: list, accuracy: float, f1: float) -> ct.models.MLModel:
    tfidf: TfidfVectorizer = pipeline.named_steps["tfidf"]
    clf: LogisticRegression = pipeline.named_steps["clf"]

    sample_input = {"normalized_description": "starbucks coffee", "amount_cents": 500}

    def sklearn_predict(normalized_description, amount_cents):  # noqa: ARG001
        proba = pipeline.predict_proba([normalized_description])[0]
        idx = int(np.argmax(proba))
        return classes[idx], {c: float(p) for c, p in zip(classes, proba)}

    model = ct.convert(
        pipeline,
        convert_to="mlprogram",
        inputs=[ct.TensorType(name="normalized_description", shape=(1,), dtype=str)],
        source="sklearn",
        classifier_config=ct.ClassifierConfig(classes),
    )
    model.short_description = "FinanceOS Transaction Category Classifier"
    model.version = f"coreml-{datetime.now(timezone.utc).strftime('%Y%m%d')}"
    model.author = "FinanceOS Intelligence Pipeline"
    model.input_description["normalized_description"] = "Cleaned, lowercased transaction description"
    model.output_description["category"] = "Predicted top-level category ID"
    model.output_description["categoryProbability"] = "Per-class confidence scores"
    return model


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train FinanceOS transaction category classifier")
    parser.add_argument("--data", default="fixtures/sample_transactions.csv", help="Training CSV path")
    parser.add_argument("--output", default="models/", help="Output directory for model artifacts")
    args = parser.parse_args()
    train(args.data, args.output)
