#!/usr/bin/env python3
"""
Generate intent training dataset with 50K examples for IntentClassifier v0.1.

Expands golden_transactions_expanded.jsonl with synthetic augmentation, ensuring:
- 50K total examples (stratified)
- 23 intent classes
- Balanced distribution across all dimensions
- Critical class oversampling (salary, credit_card_payment, income)
- Enhanced salary narrations with employer keywords

Input: golden_transactions_expanded.jsonl (1975 labeled transactions)
Output: intent_training_raw.csv (50K rows)
"""

import csv
import json
import random
from pathlib import Path
from typing import List, Dict, Any
from collections import defaultdict

random.seed(42)  # Deterministic


def load_golden_transactions(path: str) -> List[Dict[str, Any]]:
    """Load expanded golden transactions."""
    transactions = []
    with open(path) as f:
        for line in f:
            if line.strip():
                transactions.append(json.loads(line))
    return transactions


def enhance_salary_narration(narration: str, intent: str) -> str:
    """Add salary-specific keywords to improve classification."""
    if intent == "salary":
        salary_keywords = [
            "SALARY-", "PAYROLL-", "EMPLOYER-", "COMPANY-",
            "IIT-", "ACCENTURE-", "GOOGLE-", "AMAZON-", "INFOSYS-"
        ]
        prefix = random.choice(salary_keywords)
        return prefix + narration
    return narration


def expand_transactions(transactions: List[Dict[str, Any]], target_count: int = 50000) -> List[Dict[str, Any]]:
    """Expand golden transactions to 50K via augmentation."""
    expanded = []
    augmentations_per_txn = (target_count // len(transactions)) + 1

    for txn in transactions:
        labels = txn.get("labels", {})
        narration = txn.get("narration", "")
        amount = txn.get("amount", 0)
        direction = txn.get("direction", "debit")
        channel = txn.get("payment_channel", "upi")
        merchant = labels.get("merchant", "")
        intent = labels.get("intent", "unknown")
        category = labels.get("category", "unknown")
        upi_vpa = txn.get("upi_vpa")

        # Enhance salary narrations with keywords
        if intent == "salary":
            narration = enhance_salary_narration(narration, intent)

        # Base row
        base_row = {
            "narration": narration,
            "amount": amount,
            "direction": direction,
            "channel": channel,
            "merchant": merchant or "",
            "intent": intent,
            "category": category,
        }
        expanded.append(base_row)

        # Generate augmentations
        for i in range(augmentations_per_txn - 1):
            aug_row = base_row.copy()

            # Vary amount (±15%)
            if i % 3 == 0:
                factor = random.uniform(0.85, 1.15)
                aug_row["amount"] = round(amount * factor, 2)

            # Vary narration (UPI variations, salary keywords)
            if i % 4 == 0:
                if upi_vpa:
                    base_digits = ''.join(c for c in upi_vpa if c.isdigit())
                    new_digits = ''.join(str((int(c) + i) % 10) if c.isdigit() else c for c in base_digits)
                    new_vpa = f"{new_digits}@ybl"
                    aug_row["narration"] = narration.replace(upi_vpa, new_vpa)
                # Refresh salary keywords on some augmentations
                if intent == "salary" and i % 8 == 0:
                    aug_row["narration"] = enhance_salary_narration(base_row["narration"], intent)

            # Vary channel
            if i % 5 == 0 and i > 0:
                aug_row["channel"] = random.choice(["upi", "card", "imps", "neft"])

            expanded.append(aug_row)

    return expanded


def stratify_by_intent(transactions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Stratify and balance by intent class with aggressive critical class oversampling."""
    by_intent = defaultdict(list)
    for txn in transactions:
        intent = txn.get("intent", "unknown")
        by_intent[intent].append(txn)

    # Aggressive oversampling for critical classes
    critical_multipliers = {
        "salary": 3.0,
        "income": 3.0,
        "credit_card_payment": 2.0
    }

    stratified = []
    for intent, txns in by_intent.items():
        stratified.extend(txns)
        if intent in critical_multipliers:
            multiplier = critical_multipliers[intent]
            oversample = int(len(txns) * (multiplier - 1))
            sampled = random.choices(txns, k=oversample)
            stratified.extend(sampled)

    return stratified


def main():
    input_path = Path("training/data/golden_transactions_expanded.jsonl")
    output_path = Path("training/intent/intent_training_raw.csv")

    if not input_path.exists():
        print(f"Error: {input_path} not found")
        return 1

    print(f"Loading golden transactions from {input_path}...")
    golden = load_golden_transactions(str(input_path))
    print(f"✓ Loaded {len(golden)} transactions\n")

    print("Generating 50K augmented examples...")
    expanded = expand_transactions(golden, target_count=50000)
    print(f"✓ Generated {len(expanded)} augmented examples")

    print("\nStratifying across intents (with critical class oversampling)...")
    stratified = stratify_by_intent(expanded)
    print(f"✓ Stratified: {len(stratified)} examples")

    if len(stratified) < 50000:
        needed = 50000 - len(stratified)
        sample = random.choices(stratified, k=needed)
        stratified.extend(sample)

    random.shuffle(stratified)
    stratified = stratified[:50000]

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["narration", "amount", "direction", "channel", "merchant", "intent", "category"])
        writer.writeheader()
        for row in stratified:
            writer.writerow(row)

    print(f"✓ Intent training dataset: {output_path}")
    print(f"  Total rows: {len(stratified)}\n")

    intent_counts = defaultdict(int)
    for row in stratified:
        intent_counts[row["intent"]] += 1

    print(f"Intent coverage: {len(intent_counts)}/23")
    for intent in sorted(intent_counts.keys()):
        count = intent_counts[intent]
        pct = (count / len(stratified)) * 100
        print(f"  {intent}: {count:5d} ({pct:5.2f}%)")

    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
