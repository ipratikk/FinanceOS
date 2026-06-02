#!/usr/bin/env python3
"""
Export labeled training data from golden dataset to stratified CSVs.

Generates category_training_raw.csv and merchant_training_raw.csv from
golden_transactions.jsonl with synthetic augmentation (10x UPI variations,
bank format variations).

Usage:
  python export.py --input golden_transactions.jsonl \\
    --output-dir ./training_data
"""

import argparse
import json
import random
from pathlib import Path
from typing import List, Dict, Any, Optional
from collections import defaultdict
import csv
import sys

sys.path.insert(0, str(Path(__file__).parent.parent))
from benchmark_base import GoldenDatasetLoader


def load_golden_transactions(input_path: str) -> List[Dict[str, Any]]:
    """Load golden transactions from JSONL."""
    loader = GoldenDatasetLoader(input_path)
    return loader.transactions


def generate_upi_variations(vpa: str, merchant: str, count: int = 10) -> List[str]:
    """Generate synthetic UPI VPA variations."""
    variations = [vpa]  # Include original
    base_digits = ''.join(c for c in vpa if c.isdigit())
    for i in range(count - 1):
        new_digits = ''.join(
            str((int(c) + i) % 10) if c.isdigit() else c
            for c in base_digits
        )
        variations.append(f"{new_digits}@ybl")
    return variations


def generate_bank_narration_variations(
    narration: str, bank: str, vpa: Optional[str] = None
) -> List[str]:
    """Generate narration variations for different bank formats."""
    variations = [narration]
    bank_vpa_maps = {
        "HDFC": "@okhdfcbank",
        "ICICI": "@okaxis",
        "SBI": "@oksbi",
    }
    if vpa and bank in bank_vpa_maps:
        base_digits = ''.join(c for c in vpa if c.isdigit())
        new_vpa = f"{base_digits}{bank_vpa_maps[bank]}"
        modified = narration.replace(vpa, new_vpa) if vpa in narration else narration
        variations.append(modified)
    return variations


def export_category_training(
    transactions: List[Dict[str, Any]],
    output_path: str,
    augment: bool = True,
    augmentation_factor: int = 10
):
    """Export category training data to CSV."""
    rows = []
    seen_combinations = set()

    for txn in transactions:
        labels = txn.get("labels", {})
        category = labels.get("category")
        narration = txn.get("narration", "")
        amount = txn.get("amount", 0)
        direction = txn.get("direction", "debit")

        if not category or not narration:
            continue

        # Base row
        row_key = (narration, category)
        if row_key not in seen_combinations:
            rows.append({
                "narration": narration,
                "amount": amount,
                "direction": direction,
                "category": category,
            })
            seen_combinations.add(row_key)

        # Augmentation: UPI variations
        if augment and txn.get("payment_channel") == "upi" and txn.get("upi_vpa"):
            vpa = txn.get("upi_vpa")
            merchant = labels.get("merchant", "MERCHANT")
            variations = generate_upi_variations(vpa, merchant, augmentation_factor)
            for var_vpa in variations[1:]:  # Skip original
                narr_variant = narration.replace(vpa, var_vpa)
                aug_key = (narr_variant, category)
                if aug_key not in seen_combinations:
                    rows.append({
                        "narration": narr_variant,
                        "amount": amount,
                        "direction": direction,
                        "category": category,
                    })
                    seen_combinations.add(aug_key)

    output = Path(output_path)
    output.parent.mkdir(parents=True, exist_ok=True)

    with open(output, "w", newline="") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["narration", "amount", "direction", "category"]
        )
        writer.writeheader()
        writer.writerows(rows)

    print(f"✓ Category training: {len(rows)} rows → {output}")


def export_merchant_training(
    transactions: List[Dict[str, Any]],
    output_path: str,
    augment: bool = True,
    augmentation_factor: int = 10
):
    """Export merchant training data to CSV."""
    rows = []
    seen_combinations = set()

    for txn in transactions:
        labels = txn.get("labels", {})
        merchant = labels.get("merchant")
        category = labels.get("category")
        narration = txn.get("narration", "")

        if not merchant or not narration or not category:
            continue

        # Base row
        row_key = (narration, merchant)
        if row_key not in seen_combinations:
            rows.append({
                "narration": narration,
                "merchant": merchant,
                "category": category,
            })
            seen_combinations.add(row_key)

        # Augmentation: UPI variations
        if augment and txn.get("payment_channel") == "upi" and txn.get("upi_vpa"):
            vpa = txn.get("upi_vpa")
            variations = generate_upi_variations(vpa, merchant, augmentation_factor)
            for var_vpa in variations[1:]:  # Skip original
                narr_variant = narration.replace(vpa, var_vpa)
                aug_key = (narr_variant, merchant)
                if aug_key not in seen_combinations:
                    rows.append({
                        "narration": narr_variant,
                        "merchant": merchant,
                        "category": category,
                    })
                    seen_combinations.add(aug_key)

    output = Path(output_path)
    output.parent.mkdir(parents=True, exist_ok=True)

    with open(output, "w", newline="") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["narration", "merchant", "category"]
        )
        writer.writeheader()
        writer.writerows(rows)

    print(f"✓ Merchant training: {len(rows)} rows → {output}")


def main():
    parser = argparse.ArgumentParser(
        description="Export training data from golden transactions"
    )
    parser.add_argument(
        "--input",
        default="golden_transactions.jsonl",
        help="Input golden transactions JSONL file"
    )
    parser.add_argument(
        "--output-dir",
        default="./training_data",
        help="Output directory for training CSVs"
    )
    parser.add_argument(
        "--no-augment",
        action="store_true",
        help="Skip synthetic augmentation"
    )
    parser.add_argument(
        "--augmentation-factor",
        type=int,
        default=10,
        help="Multiplier for synthetic variations per UPI transaction"
    )

    args = parser.parse_args()
    input_path = Path(args.input)

    if not input_path.exists():
        print(f"Error: {input_path} not found")
        sys.exit(1)

    print(f"Loading golden transactions from {input_path}...")
    transactions = load_golden_transactions(str(input_path))

    print(f"Exporting {len(transactions)} transactions to {args.output_dir}/")
    print(f"Augmentation: {'enabled' if not args.no_augment else 'disabled'}\n")

    output_dir = Path(args.output_dir)
    export_category_training(
        transactions,
        str(output_dir / "category_training_raw.csv"),
        augment=not args.no_augment,
        augmentation_factor=args.augmentation_factor
    )
    export_merchant_training(
        transactions,
        str(output_dir / "merchant_training_raw.csv"),
        augment=not args.no_augment,
        augmentation_factor=args.augmentation_factor
    )

    print("\n✓ Export complete")


if __name__ == "__main__":
    main()
