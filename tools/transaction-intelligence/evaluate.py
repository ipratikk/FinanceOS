#!/usr/bin/env python3
"""
Evaluate CoreML model against training data.

Usage:
    python evaluate.py --data fixtures/sample_transactions.csv --model models/TransactionCategoryClassifier.mlpackage
"""

import argparse
import coremltools as ct
import pandas as pd
from sklearn.metrics import accuracy_score, classification_report, f1_score
from sklearn.preprocessing import LabelEncoder


def evaluate(data_path: str, model_path: str) -> None:
    print(f"Loading model: {model_path}")
    model = ct.models.MLModel(model_path)

    print(f"Loading data: {data_path}")
    df = pd.read_csv(data_path)
    df_clean = df[df["user_category"].notna() & df["raw_description"].notna()].copy()

    le = LabelEncoder()
    y_true = le.fit_transform(df_clean["user_category"].tolist())
    classes = le.classes_.tolist()

    y_pred_labels = []
    for _, row in df_clean.iterrows():
        desc = str(row["raw_description"]).lower().strip()
        if "canonical_merchant" in df_clean.columns and pd.notna(row.get("canonical_merchant")):
            merchant = str(row["canonical_merchant"]).lower()
            desc = f"{desc} {merchant}"
        try:
            result = model.predict({"normalized_description": desc})
            y_pred_labels.append(result.get("category", "uncategorized"))
        except Exception as e:
            print(f"  Prediction failed: {e}")
            y_pred_labels.append("uncategorized")

    y_pred = le.transform([l if l in le.classes_ else "uncategorized" for l in y_pred_labels])

    acc = accuracy_score(y_true, y_pred)
    macro_f1 = f1_score(y_true, y_pred, average="macro", zero_division=0)

    print(f"\nAccuracy:  {acc:.4f}")
    print(f"Macro F1:  {macro_f1:.4f}")
    print("\nPer-class report:")
    print(classification_report(y_true, y_pred, target_names=classes, zero_division=0))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Evaluate FinanceOS CoreML classifier")
    parser.add_argument("--data", default="fixtures/sample_transactions.csv")
    parser.add_argument("--model", default="models/TransactionCategoryClassifier.mlpackage")
    args = parser.parse_args()
    evaluate(args.data, args.model)
