#!/usr/bin/env python3
"""
Evaluate NarrationEmbedder v0.1 against acceptance thresholds.

Metrics:
- Same-merchant cosine similarity (mean over same-merchant pairs)
- Diff-merchant cosine similarity (random sample of 1,000 cross-merchant pairs)
- ANN Top-1 recall (FAISS flat index over held-out narrations)

Thresholds read from training/config/benchmark_thresholds.yaml → embedding_encoder.
Exits with code 1 if any threshold is missed.
"""

import random
import sys
from collections import defaultdict
from pathlib import Path

import numpy as np
import yaml

sys.path.insert(0, str(Path(__file__).parent.parent))
from benchmark_base import GoldenDatasetLoader

GOLDEN_PATH = Path(__file__).parent.parent / "data" / "golden_transactions_expanded.jsonl"
CHECKPOINT_PATH = Path(__file__).parent / "models" / "NarrationEmbedder_v0.1.pt"
THRESHOLDS_PATH = Path(__file__).parent.parent / "config" / "benchmark_thresholds.yaml"
RANDOM_SEED = 42


def load_thresholds():
    with open(THRESHOLDS_PATH) as f:
        config = yaml.safe_load(f)
    return config["models"]["embedding_encoder"]["metrics"]


def load_model():
    import torch
    from train import NarrationEmbedder
    checkpoint = torch.load(CHECKPOINT_PATH, map_location="cpu")
    model = NarrationEmbedder(checkpoint["base_model"], checkpoint["output_dim"])
    model.load_state_dict(checkpoint["model_state_dict"])
    model.eval()
    return model


def embed_batch(model, texts: list[str]) -> np.ndarray:
    return model.encode_for_eval(texts).cpu().numpy()


def build_merchant_groups(transactions):
    groups = defaultdict(list)
    for t in transactions:
        merchant = t.get("labels", {}).get("merchant")
        if merchant:
            groups[merchant].append(t["narration"])
    return {m: narrs for m, narrs in groups.items() if len(narrs) >= 2}


def compute_same_merchant_sim(model, merchant_groups, rng):
    pairs = []
    for merchant, narrations in merchant_groups.items():
        for i in range(len(narrations)):
            for j in range(i + 1, len(narrations)):
                pairs.append((narrations[i], narrations[j]))

    rng.shuffle(pairs)
    pairs = pairs[:500]

    anchors = [p[0] for p in pairs]
    positives = [p[1] for p in pairs]
    a_emb = embed_batch(model, anchors)
    p_emb = embed_batch(model, positives)
    sims = np.sum(a_emb * p_emb, axis=1)
    return float(np.mean(sims))


def compute_diff_merchant_sim(model, merchant_groups, rng, n_pairs=1000):
    merchants = list(merchant_groups.keys())
    pairs = []
    for _ in range(n_pairs):
        m1, m2 = rng.sample(merchants, 2)
        n1 = rng.choice(merchant_groups[m1])
        n2 = rng.choice(merchant_groups[m2])
        pairs.append((n1, n2))

    a_emb = embed_batch(model, [p[0] for p in pairs])
    b_emb = embed_batch(model, [p[1] for p in pairs])
    sims = np.sum(a_emb * b_emb, axis=1)
    return float(np.mean(sims))


def compute_ann_top1_recall(model, merchant_groups, rng):
    import faiss

    all_narrations = []
    labels = []
    for merchant, narrations in merchant_groups.items():
        for narration in narrations:
            all_narrations.append(narration)
            labels.append(merchant)

    rng.shuffle(list(zip(all_narrations, labels)))

    embeddings = embed_batch(model, all_narrations)
    dim = embeddings.shape[1]

    index = faiss.IndexFlatIP(dim)
    index.add(embeddings.astype(np.float32))

    correct = 0
    total = len(all_narrations)
    for i in range(total):
        _, top_indices = index.search(embeddings[i:i+1].astype(np.float32), k=2)
        retrieved = top_indices[0][1]
        if labels[retrieved] == labels[i]:
            correct += 1

    return correct / total


def main():
    rng = random.Random(RANDOM_SEED)

    if not CHECKPOINT_PATH.exists():
        print(f"✗ Checkpoint not found: {CHECKPOINT_PATH}. Run train.py first.")
        sys.exit(1)

    thresholds = load_thresholds()
    print(f"✓ Thresholds: same_merchant≥{thresholds['same_merchant_cosine_sim']}, "
          f"diff_merchant≤{thresholds['diff_merchant_cosine_sim']}, "
          f"ann_recall≥{thresholds['ann_top_1_recall']}")

    model = load_model()
    print("✓ Model loaded")

    loader = GoldenDatasetLoader(str(GOLDEN_PATH))
    merchant_groups = build_merchant_groups(loader.transactions)
    print(f"✓ {len(merchant_groups)} merchants")

    print("\nComputing same-merchant similarity...")
    same_sim = compute_same_merchant_sim(model, merchant_groups, rng)
    same_pass = same_sim >= thresholds["same_merchant_cosine_sim"]
    print(f"  same_merchant_cosine_sim: {same_sim:.4f} {'✓ PASS' if same_pass else '✗ FAIL'} (threshold ≥{thresholds['same_merchant_cosine_sim']})")

    print("Computing diff-merchant similarity...")
    diff_sim = compute_diff_merchant_sim(model, merchant_groups, rng)
    diff_pass = diff_sim <= thresholds["diff_merchant_cosine_sim"]
    print(f"  diff_merchant_cosine_sim: {diff_sim:.4f} {'✓ PASS' if diff_pass else '✗ FAIL'} (threshold ≤{thresholds['diff_merchant_cosine_sim']})")

    print("Computing ANN Top-1 recall...")
    ann_recall = compute_ann_top1_recall(model, merchant_groups, rng)
    ann_pass = ann_recall >= thresholds["ann_top_1_recall"]
    print(f"  ann_top_1_recall:         {ann_recall:.4f} {'✓ PASS' if ann_pass else '✗ FAIL'} (threshold ≥{thresholds['ann_top_1_recall']})")

    all_pass = same_pass and diff_pass and ann_pass
    print(f"\n{'✓ ALL THRESHOLDS PASSED' if all_pass else '✗ SOME THRESHOLDS FAILED'}")

    if not all_pass:
        sys.exit(1)


if __name__ == "__main__":
    main()
