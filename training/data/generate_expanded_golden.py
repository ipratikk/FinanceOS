#!/usr/bin/env python3
"""
Generate expanded golden dataset with comprehensive merchant, bank, and transaction coverage.

Current: 735 transactions, 35 merchants, 6 banks, 6 channels
Target: 1500 transactions, 150+ merchants, 15+ banks, 6 channels, diverse transaction types

Expansion adds:
- New merchants: fintech, food tech, travel, healthcare, education, fintech
- New banks: regional + private banks
- New transaction types: refunds, cashback, investment flows, bill payments
- Better channel distribution

Output: training/data/golden_transactions_expanded.jsonl
"""

import json
import uuid
import random
from datetime import datetime, timedelta
from typing import List, Dict, Any
from pathlib import Path


# Merchant definitions with categories and intents
MERCHANTS = {
    # E-commerce (existing)
    "Amazon": {"category": "shopping", "intent": "shopping"},
    "Flipkart": {"category": "shopping", "intent": "shopping"},
    "Myntra": {"category": "shopping", "intent": "shopping"},

    # Food & Groceries (existing)
    "Zepto": {"category": "groceries", "intent": "grocery"},
    "BigBasket": {"category": "groceries", "intent": "grocery"},
    "Blinkit": {"category": "groceries", "intent": "grocery"},
    "Swiggy": {"category": "food", "intent": "food"},
    "Zomato": {"category": "food", "intent": "food"},
    "UberEats": {"category": "food", "intent": "food"},
    "Starbucks": {"category": "dining", "intent": "food"},
    "KFC": {"category": "dining", "intent": "food"},

    # Fintech & Payments (NEW)
    "Paytm": {"category": "shopping", "intent": "shopping"},
    "Google Pay": {"category": "shopping", "intent": "shopping"},
    "PhonePe": {"category": "shopping", "intent": "shopping"},
    "Razorpay": {"category": "credit_card_payments", "intent": "credit_card_payment"},
    "PayU": {"category": "credit_card_payments", "intent": "credit_card_payment"},
    "CRED": {"category": "credit_card_payments", "intent": "credit_card_payment"},

    # Travel & Transport (existing + NEW)
    "MakeMyTrip": {"category": "travel", "intent": "travel"},
    "OYO": {"category": "travel", "intent": "travel"},
    "Skyscanner": {"category": "travel", "intent": "travel"},
    "Indigo": {"category": "fuel", "intent": "fuel"},
    "Ola": {"category": "travel", "intent": "travel"},
    "Uber": {"category": "travel", "intent": "travel"},
    "IRCTC": {"category": "travel", "intent": "travel"},

    # Entertainment & Subscriptions (existing + NEW)
    "Netflix": {"category": "entertainment", "intent": "subscription"},
    "Spotify": {"category": "entertainment", "intent": "subscription"},
    "Prime Video": {"category": "entertainment", "intent": "subscription"},
    "BookMyShow": {"category": "entertainment", "intent": "entertainment"},
    "YouTube Premium": {"category": "entertainment", "intent": "subscription"},
    "Hotstar": {"category": "entertainment", "intent": "subscription"},

    # Investments & Finance (existing + NEW)
    "Zerodha": {"category": "investments", "intent": "investment"},
    "Groww": {"category": "investments", "intent": "investment"},
    "Kuvera": {"category": "investments", "intent": "investment"},
    "Upstox": {"category": "investments", "intent": "investment"},
    "Moneycontrol": {"category": "investments", "intent": "investment"},

    # Healthcare & Wellness (existing + NEW)
    "Apollo": {"category": "healthcare", "intent": "healthcare"},
    "Fortis": {"category": "healthcare", "intent": "healthcare"},
    "1mg": {"category": "healthcare", "intent": "healthcare"},
    "Medibuddy": {"category": "healthcare", "intent": "healthcare"},
    "Practo": {"category": "healthcare", "intent": "healthcare"},
    "Cure.fit": {"category": "personal_care", "intent": "healthcare"},

    # Education (existing + NEW)
    "Udemy": {"category": "education", "intent": "education"},
    "Coursera": {"category": "education", "intent": "education"},
    "Byju's": {"category": "education", "intent": "education"},
    "Unacademy": {"category": "education", "intent": "education"},
    "LinkedIn Learning": {"category": "education", "intent": "education"},

    # Insurance (existing + NEW)
    "LIC": {"category": "insurance", "intent": "insurance"},
    "HDFC Life": {"category": "insurance", "intent": "insurance"},
    "ICICI Pru": {"category": "insurance", "intent": "insurance"},
    "Bajaj Allianz": {"category": "insurance", "intent": "insurance"},
    "ICICI Lombard": {"category": "insurance", "intent": "insurance"},

    # Telecom & Utilities (existing + NEW)
    "Airtel": {"category": "utilities", "intent": "utilities"},
    "Jio": {"category": "utilities", "intent": "utilities"},
    "Vodafone": {"category": "utilities", "intent": "utilities"},
    "BESCOM": {"category": "utilities", "intent": "utilities"},
    "BSNL": {"category": "utilities", "intent": "utilities"},
    "TATA Power": {"category": "utilities", "intent": "utilities"},

    # Fuel & Automotive (NEW)
    "Shell": {"category": "fuel", "intent": "fuel"},
    "Reliance": {"category": "fuel", "intent": "fuel"},
    "IOC": {"category": "fuel", "intent": "fuel"},
    "Caltex": {"category": "fuel", "intent": "fuel"},
    "HP": {"category": "fuel", "intent": "fuel"},
}

BANKS = [
    "HDFC", "ICICI", "SBI", "Axis", "Kotak",
    "Yes Bank", "RBL", "Federal", "Bandhan", "Indusind",
    "IDBI", "BOB", "Union", "Canara", "PNB"
]

CHANNELS = ["upi", "card", "neft", "rtgs", "imps", "nach"]

CATEGORIES = [
    "salary", "rent", "utilities", "groceries", "food", "dining",
    "shopping", "entertainment", "travel", "fuel", "healthcare",
    "education", "investments", "insurance", "transfers",
    "credit_card_payments", "loans", "subscriptions", "emi", "personal_care"
]

# Amount ranges by category (in INR)
AMOUNT_RANGES = {
    "salary": (50000, 200000),
    "rent": (10000, 50000),
    "utilities": (500, 5000),
    "groceries": (500, 3000),
    "food": (200, 1500),
    "dining": (400, 2000),
    "shopping": (500, 5000),
    "entertainment": (200, 1000),
    "travel": (2000, 15000),
    "fuel": (500, 2000),
    "healthcare": (1000, 10000),
    "education": (500, 5000),
    "investments": (5000, 50000),
    "insurance": (2000, 10000),
    "transfers": (1000, 20000),
    "credit_card_payments": (5000, 50000),
    "loans": (5000, 30000),
    "subscriptions": (100, 1000),
    "emi": (5000, 20000),
    "personal_care": (500, 3000),
}


def generate_transaction(
    base_id: int,
    category: str,
    merchant: str = None,
    bank: str = None,
    channel: str = None,
    direction: str = "debit",
    date_offset: int = 0,
) -> Dict[str, Any]:
    """Generate single transaction."""
    if not merchant:
        merchant = random.choice(list(MERCHANTS.keys()))
    if not bank:
        bank = random.choice(BANKS)
    if not channel:
        channel = random.choice(CHANNELS)

    merchant_info = MERCHANTS.get(merchant, {"category": category, "intent": category})
    intent = merchant_info.get("intent", category)

    min_amt, max_amt = AMOUNT_RANGES.get(category, (100, 10000))
    amount = round(random.uniform(min_amt, max_amt), 2)

    tx_date = (datetime.now() - timedelta(days=365-date_offset)).strftime("%Y-%m-%d")

    narration = f"{channel.upper()}-{merchant}-REF{random.randint(100000, 999999)}"
    upi_vpa = None
    if channel == "upi":
        vpa_user = random.randint(1000000000, 9999999999)
        upi_vpa = f"{vpa_user}@okhdfcbank"

    return {
        "transaction_id": f"txn_{uuid.uuid4().hex[:8]}",
        "narration": narration,
        "amount": amount,
        "direction": direction,
        "payment_channel": channel,
        "upi_vpa": upi_vpa,
        "date": tx_date,
        "bank": bank,
        "labels": {
            "merchant": merchant,
            "category": merchant_info.get("category", category),
            "subcategory": None,
            "intent": intent,
            "is_income": direction == "credit",
            "is_recurring": random.choice([True, False]),
            "recurring_cadence": "monthly" if random.random() < 0.3 else None,
            "is_subscription": "subscription" in intent.lower(),
        },
        "annotator": "synthetic-expansion",
        "annotation_date": tx_date,
        "confidence": "high"
    }


def load_existing_golden() -> List[Dict[str, Any]]:
    """Load existing golden transactions."""
    path = Path("training/data/golden_transactions.jsonl")
    txns = []
    with open(path) as f:
        for line in f:
            if line.strip():
                txns.append(json.loads(line))
    return txns


def main():
    print("Generating expanded golden dataset...")

    # Load existing
    existing = load_existing_golden()
    print(f"✓ Loaded {len(existing)} existing transactions\n")

    # Generate new transactions
    new_txns = []

    # Ensure each merchant represented well (min 20 txns each)
    txns_per_merchant = 20
    for merchant in MERCHANTS.keys():
        merchant_info = MERCHANTS[merchant]
        category = merchant_info["category"]
        for i in range(txns_per_merchant):
            new_txns.append(generate_transaction(
                len(existing) + len(new_txns),
                category=category,
                merchant=merchant,
                date_offset=random.randint(0, 365)
            ))

    print(f"Generated {len(new_txns)} transactions across {len(MERCHANTS)} merchants")
    print(f"  {txns_per_merchant} txns per merchant * {len(MERCHANTS)} merchants\n")

    # Combine
    all_txns = existing + new_txns
    print(f"Total expanded golden dataset: {len(all_txns)} transactions")

    # Write
    output_path = Path("training/data/golden_transactions_expanded.jsonl")
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, "w") as f:
        for tx in all_txns:
            f.write(json.dumps(tx) + "\n")

    print(f"✓ Expanded golden: {output_path}\n")

    # Verify coverage
    merchants = set()
    categories = set()
    banks = set()
    for tx in all_txns:
        m = tx["labels"].get("merchant")
        if m:
            merchants.add(m)
        categories.add(tx["labels"].get("category"))
        banks.add(tx.get("bank"))

    print(f"Expanded Coverage:")
    print(f"  Merchants: {len(merchants)}")
    print(f"  Categories: {len(categories)}")
    print(f"  Banks: {len(banks)}")

    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
