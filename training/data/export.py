#!/usr/bin/env python3
"""
Export labeled training data from FinanceOS GRDB.

Generates category_training.csv and merchant_training.csv from existing
transaction history, using RuleBasedCategorizer output as weak labels.

Usage:
  python export.py --source-db /path/to/financeos.sqlite \\
    --output training_data.csv \\
    --count 5000
"""

import argparse
import json
import sqlite3
from pathlib import Path
from typing import List, Dict, Any
import csv
import hashlib
import random


def export_transactions(db_path: str, count: int = 5000) -> List[Dict[str, Any]]:
    """Export recent transactions from GRDB."""
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    # Query recent transactions with existing categorization
    cursor.execute("""
        SELECT
            id,
            narration,
            amount,
            direction,
            date
        FROM transactions
        ORDER BY date DESC
        LIMIT ?
    """, (count * 2,))  # Fetch more to account for filtering

    transactions = [dict(row) for row in cursor.fetchall()]
    conn.close()

    return transactions[:count]


def generate_golden_schema() -> str:
    """Return example golden_transactions.jsonl entry."""
    return json.dumps({
        "transaction_id": "txn_001",
        "narration": "UPI-ZEPTO MARKETPLACE PR-9876543210@ybl-ZPT0001",
        "amount": 349.00,
        "direction": "debit",
        "payment_channel": "upi",
        "upi_vpa": "9876543210@ybl",
        "date": "2026-05-15",
        "bank": "HDFC",
        "labels": {
            "merchant": "Zepto",
            "category": "groceries",
            "subcategory": None,
            "intent": "grocery",
            "is_income": False,
            "income_type": None,
            "is_recurring": False,
            "recurring_cadence": None,
            "is_subscription": False
        },
        "annotator": "human",
        "annotation_date": "2026-05-01",
        "confidence": "high"
    })


def main():
    parser = argparse.ArgumentParser(
        description="Export training data from FinanceOS GRDB"
    )
    parser.add_argument(
        "--source-db",
        required=True,
        help="Path to FinanceOS SQLite database"
    )
    parser.add_argument(
        "--output",
        default="training_data.jsonl",
        help="Output JSONL file"
    )
    parser.add_argument(
        "--count",
        type=int,
        default=500,
        help="Number of transactions to export"
    )
    parser.add_argument(
        "--schema-only",
        action="store_true",
        help="Print schema example and exit"
    )

    args = parser.parse_args()

    if args.schema_only:
        print("Golden transaction schema (JSONL format):")
        print(generate_golden_schema())
        return

    # TODO: Phase 1 stub
    # Phase 2+: Implement full export with synthetic augmentation
    print(f"[Phase 1 Stub] Would export {args.count} transactions to {args.output}")
    print(f"Source: {args.source_db}")
    print("\nImplementation deferred to Phase 2 (dataset generation)")


if __name__ == "__main__":
    main()
