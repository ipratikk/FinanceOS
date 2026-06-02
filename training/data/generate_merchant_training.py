#!/usr/bin/env python3
"""
Generate merchant training dataset with 100K examples for MerchantRecognizer v0.1.

Expands golden_transactions.jsonl with synthetic augmentation, ensuring:
- 100K total examples (stratified)
- Balanced across top merchants (50+ unique merchants)
- High quality narration patterns per merchant
- Deterministic generation with seed

Input: golden_transactions.jsonl (735 labeled transactions)
Output: merchant_training.csv (100K rows)

Augmentation strategy:
- 135x expansion per transaction (100K / 735 ≈ 136)
- UPI VPA variations (unique per transaction)
- Amount perturbation (±15%)
- Channel variations
- Merchant name variations (common aliases)
"""

import csv
import json
import random
from pathlib import Path
from typing import List, Dict, Any, Optional
from collections import defaultdict

random.seed(42)


# Merchant name variations/aliases
MERCHANT_ALIASES = {
    "Zepto": ["zepto", "ZEPTO", "zepto.com", "zepto app"],
    "BigBasket": ["bigbasket", "BIGBASKET", "bbasket", "bb"],
    "Blinkit": ["blinkit", "BLINKIT", "blink it"],
    "Swiggy": ["swiggy", "SWIGGY", "swigy"],
    "Zomato": ["zomato", "ZOMATO", "zomato app"],
    "UberEats": ["ubereats", "UBEREATS", "uber eats"],
    "Netflix": ["netflix", "NETFLIX", "netflix premium"],
    "Spotify": ["spotify", "SPOTIFY", "spotify premium"],
    "Prime Video": ["prime", "PRIME VIDEO", "amazon prime"],
    "Amazon": ["amazon", "AMAZON", "amazon.in"],
    "Flipkart": ["flipkart", "FLIPKART", "flipkart app"],
    "Myntra": ["myntra", "MYNTRA", "myntra online"],
    "Zerodha": ["zerodha", "ZERODHA", "zerodha trading"],
    "Groww": ["groww", "GROWW", "groww invest"],
    "Kuvera": ["kuvera", "KUVERA", "kuvera wealth"],
    "MakeMyTrip": ["makemytrip", "MMT", "mmt.com"],
    "OYO": ["oyo", "OYO", "oyo rooms"],
    "Skyscanner": ["skyscanner", "SKYSCANNER", "sky scanner"],
    "Airtel": ["airtel", "AIRTEL", "airtel mobile"],
    "Jio": ["jio", "JIO", "reliance jio"],
    "BESCOM": ["bescom", "BESCOM", "electricity"],
    "LIC": ["lic", "LIC", "lic insurance"],
    "HDFC Life": ["hdfc life", "HDFC LIFE", "hdfc"],
    "ICICI Pru": ["icici", "ICICI PRU", "icici prudential"],
    "Apollo": ["apollo", "APOLLO", "apollo hospital"],
    "Fortis": ["fortis", "FORTIS", "fortis hospital"],
    "Udemy": ["udemy", "UDEMY", "udemy courses"],
    "Coursera": ["coursera", "COURSERA", "coursera learn"],
    "Shell": ["shell", "SHELL", "shell petrol"],
    "Indigo": ["indigo", "INDIGO", "indigo electric"],
    "CRED": ["cred", "CRED", "cred app"],
    "AmEx": ["amex", "AMEX", "american express"],
    "Starbucks": ["starbucks", "STARBUCKS", "starbucks coffee"],
    "KFC": ["kfc", "KFC", "kfc chicken"],
}


def load_golden_transactions(path: str) -> List[Dict[str, Any]]:
    """Load golden transactions."""
    transactions = []
    with open(path) as f:
        for line in f:
            if line.strip():
                transactions.append(json.loads(line))
    return transactions


def get_merchant_alias(merchant: Optional[str]) -> str:
    """Get random alias for merchant, or generate generic one."""
    if not merchant:
        return random.choice(["UPI", "NEFT", "IMPS", "CARD"])

    aliases = MERCHANT_ALIASES.get(merchant, [merchant])
    return random.choice(aliases)


def generate_upi_variations(vpa: str, count: int = 3) -> List[str]:
    """Generate unique UPI VPA variations."""
    variations = [vpa]
    base_digits = ''.join(c for c in vpa if c.isdigit())
    for i in range(count - 1):
        new_digits = ''.join(
            str((int(c) + i + 1) % 10) if c.isdigit() else c
            for c in base_digits
        )
        variations.append(f"{new_digits}@ybl")
    return variations


def modify_narration(narration: str, vpa: Optional[str], merchant: Optional[str], variation: int) -> str:
    """Modify narration for variation."""
    if variation == 0:
        return narration

    # VPA variation
    if vpa:
        base_digits = ''.join(c for c in vpa if c.isdigit())
        new_digits = ''.join(
            str((int(c) + variation) % 10) if c.isdigit() else c
            for c in base_digits
        )
        new_vpa = f"{new_digits}@ybl"
        return narration.replace(vpa, new_vpa)

    # Merchant name variation
    if merchant:
        alias = get_merchant_alias(merchant)
        return narration.replace(merchant, alias).upper()

    return narration


def expand_transactions(transactions: List[Dict[str, Any]], target_count: int = 100000) -> List[Dict[str, Any]]:
    """Expand golden transactions to 100K via augmentation."""
    expanded = []
    augmentations_per_txn = (target_count // len(transactions)) + 1

    for txn in transactions:
        labels = txn.get("labels", {})
        narration = txn.get("narration", "")
        amount = txn.get("amount", 0)
        direction = txn.get("direction", "debit")
        channel = txn.get("payment_channel", "upi")
        merchant = labels.get("merchant")
        category = labels.get("category", "unknown")
        upi_vpa = txn.get("upi_vpa")

        # Base row
        base_row = {
            "narration": narration,
            "amount": amount,
            "direction": direction,
            "channel": channel,
            "merchant": merchant or "Unknown",
            "category": category,
        }
        expanded.append(base_row)

        # Generate augmentations
        for i in range(1, augmentations_per_txn):
            aug_row = base_row.copy()

            # Vary amount (±15%)
            if i % 2 == 0:
                factor = random.uniform(0.85, 1.15)
                aug_row["amount"] = round(amount * factor, 2)

            # Vary narration (UPI variations, merchant aliases)
            if i % 3 == 0:
                aug_row["narration"] = modify_narration(narration, upi_vpa, merchant, i)

            # Vary channel
            if i % 4 == 0:
                channels = ["upi", "card", "imps", "neft", "rtgs"]
                aug_row["channel"] = random.choice(channels)

            expanded.append(aug_row)
            if len(expanded) >= target_count:
                return expanded[:target_count]

    return expanded[:target_count]


def stratify_by_merchant(transactions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Stratify transactions across merchants."""
    merchants = defaultdict(list)
    for txn in transactions:
        merchant = txn.get("merchant", "Unknown")
        merchants[merchant].append(txn)

    # Ensure each merchant has minimum representation
    target_per_merchant = max(100, len(transactions) // (len(merchants) + 1))
    stratified = []

    for merchant in sorted(merchants.keys()):
        merchant_txns = merchants[merchant]
        if len(merchant_txns) < target_per_merchant:
            factor = (target_per_merchant // len(merchant_txns)) + 1
            merchant_txns = (merchant_txns * factor)[:target_per_merchant]
        else:
            merchant_txns = random.sample(merchant_txns, min(target_per_merchant, len(merchant_txns)))
        stratified.extend(merchant_txns)

    return stratified


def main():
    input_path = Path("training/data/golden_transactions.jsonl")
    output_path = Path("training/data/merchant_training_raw.csv")

    if not input_path.exists():
        print(f"Error: {input_path} not found")
        return 1

    print(f"Loading golden transactions from {input_path}...")
    golden = load_golden_transactions(str(input_path))
    print(f"✓ Loaded {len(golden)} transactions\n")

    print("Generating 100K augmented examples...")
    expanded = expand_transactions(golden, target_count=100000)
    print(f"✓ Generated {len(expanded)} augmented examples")

    print("\nStratifying across merchants...")
    stratified = stratify_by_merchant(expanded)

    # Ensure we have 100K minimum
    if len(stratified) < 100000:
        needed = 100000 - len(stratified)
        sample = random.choices(stratified, k=needed)
        stratified.extend(sample)

    random.shuffle(stratified)
    stratified = stratified[:100000]
    print(f"✓ Stratified: {len(stratified)} examples")

    # Write CSV
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w", newline="") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["narration", "amount", "direction", "channel", "merchant", "category"],
        )
        writer.writeheader()
        writer.writerows(stratified)

    print(f"\n✓ Merchant training dataset: {output_path}")
    print(f"  Total rows: {len(stratified)}")

    # Distribution summary
    merchant_dist = defaultdict(int)
    category_dist = defaultdict(int)
    for txn in stratified:
        merchant_dist[txn["merchant"]] += 1
        category_dist[txn["category"]] += 1

    print(f"\nMerchants covered: {len(merchant_dist)}")
    for merchant in sorted(merchant_dist.keys(), key=lambda x: -merchant_dist[x])[:15]:
        print(f"  {merchant}: {merchant_dist[merchant]}")

    print(f"\nCategories covered: {len(category_dist)}")

    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
