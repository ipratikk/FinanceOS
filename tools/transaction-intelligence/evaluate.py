#!/usr/bin/env python3
"""
Evaluate a previously trained Core ML transaction category classifier.

Usage:
    python evaluate.py --data fixtures/sample_transactions.csv --model models/TransactionCategoryClassifier.mlpackage
"""

import argparse
import json
from pathlib import Path

import coremltools as ct
import pandas as pd
from sklearn.metrics import accuracy_score, classification_report, f1_score
from sklearn.preprocessing import LabelEncoder


def evaluate(data_path: str, model_path: str) -> None:
    print(f"Loading model: {model_path}")
    model = ct.models.MLModel(model_path)

    print(f"Loading data: {data_path}")
    df = pd.read_csv(data_path)
    df = df[df["user_category"].notna() & df["raw_description"].notna()].copy()

    le = LabelEncoder()
    y_true = le.fit_transform(df["user_category"].tolist())
    classes = le.classes_.tolist()

    y_pred_labels = []
    for _, row in df.iterrows():
        desc = str(row["raw_description"]).lower().strip()
        result = model.predict({"normalized_description": desc})
        y_pred_labels.append(result.get("category", "uncategorized"))

    y_pred = le.transform([l if l in le.classes_ else "uncategorized" for l in y_pred_labels])

    acc = accuracy_score(y_true, y_pred)
    macro_f1 = f1_score(y_true, y_pred, average="macro", zero_division=0)

    print(f"\nAccuracy:  {acc:.4f}")
    print(f"Macro F1:  {macro_f1:.4f}")
    print("\nPer-class report:")
    print(classification_report(y_true, y_pred, target_names=classes, zero_division=0))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Evaluate FinanceOS transaction category classifier")
    parser.add_argument("--data", default="fixtures/sample_transactions.csv")
    parser.add_argument("--model", default="models/TransactionCategoryClassifier.mlpackage")
    args = parser.parse_args()
    evaluate(args.data, args.model)
