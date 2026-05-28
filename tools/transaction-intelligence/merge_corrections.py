#!/usr/bin/env python3
"""
Merge user corrections CSV into main training data.

Usage:
    python merge_corrections.py \
        --corrections corrections_export.csv \
        --training fixtures/sample_transactions.csv \
        --output merged_training.csv

Corrections override any existing row with the same transaction id.
Rows without a user_category are dropped (validation step).
"""

import argparse
import sys
from pathlib import Path

import pandas as pd


def merge(corrections_path: str, training_path: str, output_path: str) -> None:
    corrections = pd.read_csv(corrections_path)
    training = pd.read_csv(training_path)

    print(f"Training rows:    {len(training)}")
    print(f"Correction rows:  {len(corrections)}")

    # Map corrections columns to training schema
    mapped = pd.DataFrame({
        "id": corrections["id"],
        "date": corrections.get("date", ""),
        "amount": None,
        "currency": None,
        "raw_description": corrections.get("raw_description", ""),
        "merchant_name": None,
        "canonical_merchant": corrections.get("corrected_merchant", ""),
        "mcc": None,
        "account_type": None,
        "institution": None,
        "user_category": corrections["user_category"],
        "user_subcategory": None,
        "is_transfer": None,
        "is_income": None,
        "source": "user_correction",
    })

    # Drop corrections with no category
    mapped = mapped[mapped["user_category"].notna()]

    # Remove training rows whose id appears in corrections (corrections win)
    correction_ids = set(mapped["id"].dropna())
    training_filtered = training[~training["id"].isin(correction_ids)]

    merged = pd.concat([training_filtered, mapped], ignore_index=True)
    merged.to_csv(output_path, index=False)

    added = len(mapped)
    removed = len(training) - len(training_filtered)
    print(f"Removed {removed} overridden rows, added {added} corrections.")
    print(f"Merged output:    {len(merged)} rows → {output_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Merge user corrections into training data")
    parser.add_argument("--corrections", required=True)
    parser.add_argument("--training", default="fixtures/sample_transactions.csv")
    parser.add_argument("--output", default="merged_training.csv")
    args = parser.parse_args()
    merge(args.corrections, args.training, args.output)
