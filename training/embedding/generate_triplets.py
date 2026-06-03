#!/usr/bin/env python3
"""
Generate triplet dataset for NarrationEmbedder training.

Loads golden_transactions_expanded.jsonl, groups by merchant,
generates anchor/positive/negative triplets for contrastive learning.
Hard negatives are sampled from merchants sharing the same category.

Output: training/embedding/data/triplets.jsonl
"""

import json
import random
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))
from benchmark_base import GoldenDatasetLoader

GOLDEN_PATH = Path(__file__).parent.parent / "data" / "golden_transactions_expanded.jsonl"
OUTPUT_PATH = Path(__file__).parent / "data" / "triplets.jsonl"
MIN_TRIPLETS = 2000
RANDOM_SEED = 42


def build_merchant_groups(transactions):
    """Group narrations by merchant, skip null merchants."""
    groups = defaultdict(list)
    for t in transactions:
        merchant = t.get("labels", {}).get("merchant")
        if merchant:
            groups[merchant].append({
                "narration": t["narration"],
                "category": t.get("labels", {}).get("category", ""),
            })
    return {m: items for m, items in groups.items() if len(items) >= 2}


def build_category_index(merchant_groups):
    """Map category → list of merchants for hard negative sampling."""
    cat_index = defaultdict(list)
    for merchant, items in merchant_groups.items():
        category = items[0]["category"]
        cat_index[category].append(merchant)
    return cat_index


def sample_negative(anchor_merchant, anchor_category, merchant_groups, cat_index, rng):
    """Sample hard negative: same category, different merchant. Fall back to random."""
    candidates = [m for m in cat_index.get(anchor_category, []) if m != anchor_merchant]
    if not candidates:
        candidates = [m for m in merchant_groups if m != anchor_merchant]
    if not candidates:
        return None
    neg_merchant = rng.choice(candidates)
    neg_item = rng.choice(merchant_groups[neg_merchant])
    return neg_item["narration"]


def generate_triplets(merchant_groups, cat_index, rng):
    triplets = []
    for merchant, items in merchant_groups.items():
        narrations = [item["narration"] for item in items]
        category = items[0]["category"]
        pairs = [(narrations[i], narrations[j]) for i in range(len(narrations)) for j in range(i + 1, len(narrations))]
        for anchor, positive in pairs:
            negative = sample_negative(merchant, category, merchant_groups, cat_index, rng)
            if negative:
                triplets.append({"anchor": anchor, "positive": positive, "negative": negative})
    return triplets


def augment_triplets(triplets, merchant_groups, cat_index, rng, target):
    """Augment by swapping anchor/positive to reach target count."""
    swapped = [{"anchor": t["positive"], "positive": t["anchor"], "negative": t["negative"]} for t in triplets]
    combined = triplets + swapped
    rng.shuffle(combined)
    return combined[:target] if len(combined) >= target else combined


def main():
    rng = random.Random(RANDOM_SEED)

    loader = GoldenDatasetLoader(str(GOLDEN_PATH))
    merchant_groups = build_merchant_groups(loader.transactions)
    print(f"✓ {len(merchant_groups)} merchants with ≥2 narrations")

    cat_index = build_category_index(merchant_groups)

    triplets = generate_triplets(merchant_groups, cat_index, rng)
    print(f"  Generated {len(triplets)} raw triplets")

    if len(triplets) < MIN_TRIPLETS:
        triplets = augment_triplets(triplets, merchant_groups, cat_index, rng, MIN_TRIPLETS)
        print(f"  Augmented to {len(triplets)} triplets")

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_PATH, "w") as f:
        for t in triplets:
            f.write(json.dumps(t) + "\n")

    print(f"✓ Wrote {len(triplets)} triplets → {OUTPUT_PATH}")

    if len(triplets) < MIN_TRIPLETS:
        print(f"✗ FAIL: only {len(triplets)} triplets, need ≥{MIN_TRIPLETS}")
        sys.exit(1)


if __name__ == "__main__":
    main()
