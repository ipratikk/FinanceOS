#!/usr/bin/env python3
"""Validate transaction training data CSV before training."""

import sys
import pandas as pd

REQUIRED_COLUMNS = {
    "id", "date", "amount", "currency", "raw_description",
    "user_category", "is_transfer", "is_income", "source",
}

VALID_CATEGORIES = {
    "income", "transfers", "housing", "utilities", "groceries", "dining",
    "transportation", "travel", "healthcare", "insurance", "subscriptions",
    "shopping", "entertainment", "education", "fees", "taxes",
    "business", "atm", "uncategorized",
}


def validate(path: str) -> bool:
    df = pd.read_csv(path)
    errors = []

    missing = REQUIRED_COLUMNS - set(df.columns)
    if missing:
        errors.append(f"Missing required columns: {missing}")

    if "user_category" in df.columns:
        unknown = set(df["user_category"].dropna().unique()) - VALID_CATEGORIES
        if unknown:
            errors.append(f"Unknown categories: {unknown}")

    if "amount" in df.columns:
        if df["amount"].isnull().any():
            errors.append("Null values in 'amount' column")

    if "raw_description" in df.columns:
        empty_desc = df["raw_description"].isnull() | (df["raw_description"].str.strip() == "")
        if empty_desc.any():
            errors.append(f"{empty_desc.sum()} rows have empty raw_description")

    if errors:
        print("Validation FAILED:")
        for err in errors:
            print(f"  - {err}")
        return False

    labeled = df["user_category"].notna().sum() if "user_category" in df.columns else 0
    print(f"Validation PASSED: {len(df)} rows, {labeled} labeled")
    category_dist = df["user_category"].value_counts()
    print("\nCategory distribution:")
    print(category_dist.to_string())
    return True


if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "fixtures/sample_transactions.csv"
    ok = validate(path)
    sys.exit(0 if ok else 1)
