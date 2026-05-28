#!/usr/bin/env python3
"""
Train & export CoreML transaction category classifier.

Uses coremltools 6.x (supports sklearn) + ColumnTransformer for text+numeric features.

Usage:
    python train.py --data fixtures/sample_transactions.csv --output models/

Output:
    models/TransactionCategoryClassifier.mlpackage
    models/evaluation/category_metrics.json
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
from sklearn.compose import ColumnTransformer
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
from sklearn.preprocessing import LabelEncoder, StandardScaler


TAXONOMY_VERSION = "1.0.0"


def load_and_filter(path: str) -> pd.DataFrame:
    df = pd.read_csv(path)
    df = df[df["user_category"].notna()].copy()
    df = df[df["raw_description"].notna()].copy()
    df["raw_description"] = df["raw_description"].astype(str).str.strip()
    return df


def build_text_feature(df: pd.DataFrame) -> pd.Series:
    """Text feature for training. Amount handled separately in Swift."""
    desc = df["raw_description"].str.lower()
    if "canonical_merchant" in df.columns:
        merchant = df["canonical_merchant"].fillna("").str.lower()
        desc = desc + " " + merchant
    return desc


def train(data_path: str, output_dir: str) -> None:
    output = Path(output_dir)
    output.mkdir(parents=True, exist_ok=True)
    (output / "evaluation").mkdir(exist_ok=True)

    print(f"Loading data from: {data_path}")
    df = load_and_filter(data_path)
    print(f"  Labeled rows: {len(df)}")

    X_text = build_text_feature(df)
    labels = df["user_category"].tolist()

    le = LabelEncoder()
    y = le.fit_transform(labels)
    classes = le.classes_.tolist()

    min_class_count = min(pd.Series(y).value_counts().values) if len(pd.Series(y).unique()) > 0 else 0
    can_stratify = min_class_count >= 2 and len(df) >= 10
    X_train, X_test, y_train, y_test = train_test_split(
        X_text.tolist(), y, test_size=0.2, random_state=42, stratify=y if can_stratify else None
    )

    # Text-only pipeline for CoreML export. Amount feature engineering done in Swift.
    pipeline = Pipeline([
        ("tfidf", TfidfVectorizer(max_features=5000, ngram_range=(1, 2), sublinear_tf=True)),
        ("clf", LogisticRegression(max_iter=1000, C=1.0, class_weight="balanced")),
    ])
    pipeline.fit(X_train, y_train)

    y_pred = pipeline.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    macro_f1 = f1_score(y_test, y_pred, average="macro", zero_division=0)

    proba = pipeline.predict_proba(X_test) if hasattr(pipeline, 'predict_proba') else None
    top3_acc = None
    if proba is not None:
        try:
            top3_acc = top_k_accuracy_score(y_test, proba, k=3)
        except Exception:
            pass

    report = classification_report(
        y_test, y_pred, labels=np.unique(y_test),
        target_names=[classes[i] for i in np.unique(y_test)],
        zero_division=0, output_dict=True
    )
    cm = confusion_matrix(y_test, y_pred, labels=np.unique(y_test)).tolist()

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

    # Export to CoreML
    mlmodel = export_to_coreml(pipeline, classes, acc, macro_f1)
    model_path = output / "TransactionCategoryClassifier.mlpackage"
    mlmodel.save(str(model_path))
    print(f"  Model saved: {model_path}")

    # Save evaluation metrics
    metrics = {
        "accuracy": float(acc),
        "macro_f1": float(macro_f1),
        "top3_accuracy": float(top3_acc) if top3_acc else None,
        "confusion_matrix": cm,
        "class_names": classes,
        "per_class": {k: v for k, v in report.items() if isinstance(v, dict)},
        "evaluated_at": datetime.now(timezone.utc).isoformat(),
    }
    metrics_path = output / "evaluation" / "category_metrics.json"
    with open(metrics_path, "w") as f:
        json.dump(metrics, f, indent=2)
    print(f"  Metrics saved: {metrics_path}")


def export_to_coreml(pipeline: Pipeline, classes: list, accuracy: float, f1: float) -> ct.models.MLModel:
    """
    Convert sklearn text-only pipeline to Core ML.

    Input:
      - normalized_description: str (transaction description + merchant)

    Outputs:
      - category: str (predicted category ID)
      - categoryProbability: dict (per-class confidence scores)

    NOTE: Amount feature engineering done in Swift for better type safety.
    """
    # coremltools 6.x supports sklearn pipelines with proper source detection
    model = ct.convert(
        pipeline,
        classifier_config=ct.ClassifierConfig(class_labels=classes),
    )

    model.short_description = "FinanceOS Transaction Category Classifier"
    model.version = f"coreml-{datetime.now(timezone.utc).strftime('%Y%m%d')}"
    model.author = "FinanceOS Intelligence Pipeline"

    # Update input/output descriptions
    if hasattr(model, "input_description"):
        model.input_description["normalized_description"] = "Cleaned transaction description + merchant"
    if hasattr(model, "output_description"):
        model.output_description["category"] = "Predicted top-level category ID"
        model.output_description["categoryProbability"] = "Per-class confidence scores"

    return model


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train FinanceOS transaction category classifier")
    parser.add_argument("--data", default="fixtures/sample_transactions.csv", help="Training CSV path")
    parser.add_argument("--output", default="models/", help="Output directory for model artifacts")
    args = parser.parse_args()
    train(args.data, args.output)
