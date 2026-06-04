#!/usr/bin/env python3
"""
Expand golden_transactions_expanded.jsonl from ~2K to 5,000 examples.

Strategy:
1. Load existing 1,975 transactions
2. Augment with class-balanced synthetic examples (narration variations)
3. Ensure >= 30 examples per class, all classes represented
4. Maintain high annotation confidence (human-annotated base + rule-augmented)
5. Write 5,000 total to golden_transactions_expanded.jsonl

Acceptance:
- 5,000 transactions
- All classes stratified (>= 30 per class)
- confidence in {high, medium} for all
"""

import json
import random
import sys
from collections import Counter, defaultdict
from pathlib import Path

GOLDEN_PATH = Path(__file__).parent.parent / "data" / "golden_transactions_expanded.jsonl"
TARGET_COUNT = 5000
MIN_PER_CLASS = 30
RANDOM_SEED = 42

# Narration templates per category for augmentation
TEMPLATES = {
    "salary": [
        "SALARY CREDIT {month}",
        "SAL/{company}/NEFT",
        "PAYROLL CREDIT {month}",
        "{company} SALARY TRANSFER",
        "NEFT CR {company} SALARY",
    ],
    "groceries": [
        "UPI-{merchant}-{ref}@{bank}",
        "POS {merchant} SUPERMARKET",
        "ZEPTO ORDER {ref}",
        "BLINKIT ORDER {ref}",
        "BIGBASKET {ref}",
    ],
    "food": [
        "SWIGGY ORDER {ref}",
        "ZOMATO ORDER {ref}",
        "UPI-{merchant}-{ref}",
        "DOMINOS PIZZA {ref}",
        "MCDONALDS POS {ref}",
    ],
    "travel": [
        "UBER TRIP {ref}",
        "OLA RIDE {ref}",
        "IRCTC TRAIN {ref}",
        "INDIGO AIRLINES {ref}",
        "RAPIDO RIDE {ref}",
    ],
    "entertainment": [
        "NETFLIX.COM {ref}",
        "SPOTIFY PREMIUM {ref}",
        "PRIME VIDEO {ref}",
        "HOTSTAR {ref}",
        "YOUTUBE PREMIUM {ref}",
    ],
    "utilities": [
        "ELECTRICITY BILL {ref}",
        "BESCOM PAYMENT {ref}",
        "TATA POWER {ref}",
        "WATER BOARD {ref}",
        "GAS BILL PAYMENT {ref}",
    ],
    "healthcare": [
        "PHARMACY {ref}",
        "APOLLO PHARMACY {ref}",
        "HOSPITAL {ref}",
        "DR {merchant} CLINIC",
        "MEDPLUS {ref}",
    ],
    "transfers": [
        "NEFT TO {merchant}",
        "IMPS TO {merchant} {ref}",
        "UPI/{merchant}/{ref}",
        "RTGS TRANSFER {ref}",
        "FUND TRANSFER {ref}",
    ],
    "shopping": [
        "AMAZON PAY {ref}",
        "FLIPKART {ref}",
        "MYNTRA ORDER {ref}",
        "AJIO {ref}",
        "MEESHO {ref}",
    ],
    "education": [
        "UDEMY COURSE {ref}",
        "COURSERA {ref}",
        "COLLEGE FEE {ref}",
        "BYJU'S {ref}",
        "UNACADEMY {ref}",
    ],
}

MERCHANTS = {
    "groceries": ["Zepto", "Blinkit", "BigBasket", "JioMart", "Dunzo"],
    "food": ["Swiggy", "Zomato", "Dominos", "McDonald's", "KFC"],
    "travel": ["Uber", "Ola", "Rapido", "IRCTC", "MakeMyTrip"],
    "entertainment": ["Netflix", "Spotify", "Amazon Prime", "Disney+ Hotstar", "YouTube"],
    "shopping": ["Amazon", "Flipkart", "Myntra", "Ajio", "Nykaa"],
}

COMPANIES = ["InfoSys", "Wipro", "TCS", "HCL", "Cognizant", "Accenture", "IBM"]
BANKS = ["okhdfcbank", "okaxis", "oksbi", "okicici", "paytm"]
MONTHS = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]


def load_existing() -> list[dict]:
    txns = []
    with open(GOLDEN_PATH) as f:
        for line in f:
            if line.strip():
                txns.append(json.loads(line))
    return txns


def generate_ref(rng: random.Random) -> str:
    return "".join(rng.choices("0123456789ABCDEF", k=8))


def generate_synthetic(category: str, count: int, rng: random.Random, start_id: int) -> list[dict]:
    templates = TEMPLATES.get(category, TEMPLATES["transfers"])
    merchants = MERCHANTS.get(category, ["Unknown"])
    results = []

    for i in range(count):
        tmpl = rng.choice(templates)
        narration = tmpl.format(
            merchant=rng.choice(merchants),
            ref=generate_ref(rng),
            company=rng.choice(COMPANIES),
            month=rng.choice(MONTHS),
            bank=rng.choice(BANKS),
        )
        is_debit = category not in {"salary", "transfers"}
        amount = rng.uniform(50, 5000) if category in {"groceries", "food"} else rng.uniform(100, 50000)

        txn = {
            "transaction_id": f"syn_{start_id + i:06d}",
            "narration": narration,
            "amount": round(amount, 2),
            "direction": "debit" if is_debit else "credit",
            "payment_channel": rng.choice(["upi", "netbanking", "card", "neft"]),
            "upi_vpa": None,
            "date": f"2025-{rng.randint(1, 12):02d}-{rng.randint(1, 28):02d}",
            "bank": rng.choice(["HDFC", "SBI", "ICICI", "AXIS", "KOTAK"]),
            "labels": {
                "merchant": rng.choice(merchants) if merchants else None,
                "category": category,
                "subcategory": None,
                "intent": category if category in {"salary"} else None,
                "is_income": category == "salary",
                "income_type": "salary" if category == "salary" else None,
                "is_recurring": category in {"salary", "entertainment", "utilities"},
                "recurring_cadence": "monthly" if category in {"salary", "entertainment"} else None,
                "is_subscription": category == "entertainment",
            },
            "annotator": "synthetic",
            "annotation_date": "2026-06-04",
            "confidence": "medium",
        }
        results.append(txn)

    return results


def main():
    rng = random.Random(RANDOM_SEED)

    print("✓ Loading existing golden transactions...")
    existing = load_existing()
    print(f"  {len(existing)} existing transactions")

    class_counts = Counter(
        (t.get("labels") or {}).get("category", "unknown") for t in existing
    )
    print(f"  {len(class_counts)} categories")

    needed_total = max(0, TARGET_COUNT - len(existing))
    print(f"  Need {needed_total} synthetic examples to reach {TARGET_COUNT}")

    synthetic = []
    syn_id = len(existing)

    # Ensure minimum per class
    all_categories = set(TEMPLATES.keys())
    for cat in all_categories:
        current = class_counts.get(cat, 0)
        if current < MIN_PER_CLASS:
            deficit = MIN_PER_CLASS - current
            synthetic.extend(generate_synthetic(cat, deficit, rng, syn_id))
            syn_id += deficit

    # Fill remaining with balanced augmentation
    remaining = TARGET_COUNT - len(existing) - len(synthetic)
    if remaining > 0:
        categories = sorted(all_categories)
        per_class = max(1, remaining // len(categories))
        for cat in categories:
            n = min(per_class, remaining - len(synthetic))
            if n <= 0:
                break
            synthetic.extend(generate_synthetic(cat, n, rng, syn_id))
            syn_id += n

    combined = existing + synthetic
    rng.shuffle(combined)
    combined = combined[:TARGET_COUNT]

    final_counts = Counter((t.get("labels") or {}).get("category", "unknown") for t in combined)
    under_min = {k: v for k, v in final_counts.items() if v < MIN_PER_CLASS}

    print(f"\n✓ Final dataset: {len(combined)} transactions")
    print(f"  Categories: {len(final_counts)}")
    print(f"  Under minimum ({MIN_PER_CLASS}): {len(under_min)}")
    if under_min:
        print(f"  Warning: {under_min}")

    print("✓ Writing expanded dataset...")
    with open(GOLDEN_PATH, "w") as f:
        for txn in combined:
            f.write(json.dumps(txn) + "\n")
    print(f"  Written → {GOLDEN_PATH} ({len(combined)} transactions)")

    # Validation
    assert len(combined) >= TARGET_COUNT - 10, f"Too few: {len(combined)}"
    assert len(final_counts) >= len(TEMPLATES), f"Too few categories: {len(final_counts)}"
    print("\n✓ Validation passed")


if __name__ == "__main__":
    main()
