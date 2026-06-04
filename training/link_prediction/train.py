#!/usr/bin/env python3
"""
Train LinkPredictor v0.1 — TransE for KnowledgeGraph edge prediction.

Entities: merchants, categories, persons (from golden transactions)
Relations: BOUGHT_FROM, IN_CATEGORY, PAID_TO

Requirements:
- AUC-ROC >= 0.85
- Hits@1 >= 0.65
- MRR >= 0.70

Output: training/link_prediction/models/link_predictor_v0.1.npz + report
"""

import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import yaml

sys.path.insert(0, str(Path(__file__).parent.parent))
from benchmark_base import BenchmarkReport, write_report

GOLDEN_PATH = Path(__file__).parent.parent / "data" / "golden_transactions_expanded.jsonl"
MODELS_DIR = Path(__file__).parent / "models"
MODEL_PATH = MODELS_DIR / "link_predictor_v0.1.npz"
REGISTRY_PATH = MODELS_DIR / "model_registry_entry.yaml"
REPORT_PATH = Path(__file__).parent.parent / "reports" / "link_predictor_training_metrics.json"

EMBEDDING_DIM = 64
EPOCHS = 100
LR = 0.01
MARGIN = 1.0
NEG_SAMPLES = 5
RANDOM_SEED = 42


def build_graph(transactions):
    entities = set()
    relations = {"BOUGHT_FROM": 0, "IN_CATEGORY": 1, "PAID_TO": 2}
    triples = []

    for txn in transactions:
        merchant = (txn.get("labels") or {}).get("merchant") or txn.get("merchant_name")
        category = (txn.get("labels") or {}).get("category") or "unknown"
        person = txn.get("upi_vpa") or None
        txn_id = txn.get("transaction_id", str(id(txn)))

        if merchant:
            entities.add(f"txn:{txn_id}")
            entities.add(f"merchant:{merchant}")
            entities.add(f"category:{category}")
            triples.append((f"txn:{txn_id}", "BOUGHT_FROM", f"merchant:{merchant}"))
            triples.append((f"txn:{txn_id}", "IN_CATEGORY", f"category:{category}"))
            if person:
                entities.add(f"person:{person}")
                triples.append((f"txn:{txn_id}", "PAID_TO", f"person:{person}"))

    entity_list = sorted(entities)
    entity2id = {e: i for i, e in enumerate(entity_list)}
    return entity2id, relations, triples


class TransE:
    def __init__(self, n_entities, n_relations, dim=64, seed=42):
        rng = np.random.RandomState(seed)
        self.entity_emb = rng.normal(0, 0.01, (n_entities, dim)).astype(np.float32)
        self.relation_emb = rng.normal(0, 0.01, (n_relations, dim)).astype(np.float32)
        self._normalize_entities()

    def _normalize_entities(self):
        norms = np.linalg.norm(self.entity_emb, axis=1, keepdims=True)
        self.entity_emb = self.entity_emb / np.maximum(norms, 1e-9)

    def score(self, head, relation, tail):
        h = self.entity_emb[head]
        r = self.relation_emb[relation]
        t = self.entity_emb[tail]
        return -np.sum(np.abs(h + r - t), axis=-1)

    def train_step(self, pos_triples, entity2id, relation2id, lr, margin, neg_samples):
        rng = np.random.RandomState()
        n_entities = len(entity2id)
        total_loss = 0.0

        for (h_str, r_str, t_str) in pos_triples:
            h = entity2id[h_str]
            r = relation2id[r_str]
            t = entity2id[t_str]

            pos_score = self.score(h, r, t)

            for _ in range(neg_samples):
                if rng.random() < 0.5:
                    h_neg = rng.randint(n_entities)
                    neg_score = self.score(h_neg, r, t)
                else:
                    t_neg = rng.randint(n_entities)
                    neg_score = self.score(h, r, t_neg)

                loss = max(0.0, margin + neg_score - pos_score)
                total_loss += loss

                if loss > 0:
                    # Gradient update
                    diff_pos = np.sign(self.entity_emb[h] + self.relation_emb[r] - self.entity_emb[t])
                    self.entity_emb[h] -= lr * diff_pos
                    self.relation_emb[r] -= lr * diff_pos
                    self.entity_emb[t] += lr * diff_pos

        self._normalize_entities()
        return total_loss / max(len(pos_triples), 1)


def evaluate(model, test_triples, entity2id, relation2id, n_entities):
    hits_at_1 = 0
    reciprocal_ranks = []
    pos_scores = []
    neg_scores = []

    rng = np.random.RandomState(42)

    for (h_str, r_str, t_str) in test_triples:
        if h_str not in entity2id or t_str not in entity2id or r_str not in relation2id:
            continue
        h = entity2id[h_str]
        r = relation2id[r_str]
        t = entity2id[t_str]

        pos_score = float(model.score(h, r, t))
        pos_scores.append(pos_score)

        # Generate candidates (corrupt tail)
        candidates = [(h, r, rng.randint(n_entities)) for _ in range(50)]
        scores = [(model.score(hh, rr, tt), tt) for hh, rr, tt in candidates]
        scores.append((pos_score, t))
        scores.sort(reverse=True)

        rank = next(i + 1 for i, (_, tt) in enumerate(scores) if tt == t)
        if rank == 1:
            hits_at_1 += 1
        reciprocal_ranks.append(1.0 / rank)

        # Negative score
        t_neg = rng.randint(n_entities)
        while t_neg == t:
            t_neg = rng.randint(n_entities)
        neg_scores.append(float(model.score(h, r, t_neg)))

    hits1 = hits_at_1 / max(len(test_triples), 1)
    mrr = np.mean(reciprocal_ranks) if reciprocal_ranks else 0.0

    # AUC-ROC
    if pos_scores and neg_scores:
        all_scores = pos_scores + neg_scores
        all_labels = [1] * len(pos_scores) + [0] * len(neg_scores)
        from sklearn.metrics import roc_auc_score
        auc = roc_auc_score(all_labels, all_scores)
    else:
        auc = 0.5

    return {"hits_at_1": round(hits1, 4), "mrr": round(float(mrr), 4), "auc_roc": round(float(auc), 4)}


def main():
    MODELS_DIR.mkdir(parents=True, exist_ok=True)

    if not GOLDEN_PATH.exists():
        print(f"✗ Golden data not found: {GOLDEN_PATH}")
        sys.exit(1)

    print("✓ Loading transactions and building KG...")
    transactions = []
    with open(GOLDEN_PATH) as f:
        for line in f:
            if line.strip():
                transactions.append(json.loads(line))

    entity2id, relation2id, all_triples = build_graph(transactions)
    n_entities = len(entity2id)
    n_relations = len(relation2id)
    print(f"  {n_entities} entities, {n_relations} relations, {len(all_triples)} triples")

    if len(all_triples) < 10:
        print("✗ Insufficient triples for training")
        sys.exit(1)

    rng = np.random.RandomState(RANDOM_SEED)
    rng.shuffle(all_triples)
    split = int(len(all_triples) * 0.8)
    train_triples = all_triples[:split]
    test_triples = all_triples[split:]

    model = TransE(n_entities, n_relations, dim=EMBEDDING_DIM, seed=RANDOM_SEED)
    print(f"✓ Training TransE ({EPOCHS} epochs)...")

    for epoch in range(1, EPOCHS + 1):
        rng.shuffle(train_triples)
        loss = model.train_step(train_triples, entity2id, relation2id, LR, MARGIN, NEG_SAMPLES)
        if epoch % 20 == 0:
            print(f"  Epoch {epoch:3d}/{EPOCHS} | loss={loss:.4f}")

    print("✓ Evaluating...")
    metrics = evaluate(model, test_triples, entity2id, relation2id, n_entities)
    print(f"  AUC-ROC: {metrics['auc_roc']:.4f}  {'✓' if metrics['auc_roc'] >= 0.85 else '✗'}  (gate >= 0.85)")
    print(f"  Hits@1:  {metrics['hits_at_1']:.4f}  {'✓' if metrics['hits_at_1'] >= 0.65 else '✗'}  (gate >= 0.65)")
    print(f"  MRR:     {metrics['mrr']:.4f}  {'✓' if metrics['mrr'] >= 0.70 else '✗'}  (gate >= 0.70)")

    auc_pass = metrics["auc_roc"] >= 0.85
    hits_pass = metrics["hits_at_1"] >= 0.65
    mrr_pass = metrics["mrr"] >= 0.70
    all_pass = auc_pass and hits_pass and mrr_pass

    print("✓ Saving model...")
    np.savez(MODEL_PATH,
             entity_emb=model.entity_emb,
             relation_emb=model.relation_emb,
             entity_list=list(entity2id.keys()),
             relation_list=list(relation2id.keys()))
    sha256 = hashlib.sha256(MODEL_PATH.read_bytes()).hexdigest()
    size_mb = MODEL_PATH.stat().st_size / (1024 * 1024)
    print(f"  Saved → {MODEL_PATH.name} ({size_mb:.1f} MB)")

    registry = {
        "model_name": "LinkPredictor",
        "model_version": "v0.1",
        "export_date": datetime.now(timezone.utc).isoformat(),
        "algorithm": "TransE",
        "embedding_dim": EMBEDDING_DIM,
        "n_entities": n_entities,
        "n_relations": n_relations,
        "sha256": sha256,
        "metrics": metrics,
    }
    with open(REGISTRY_PATH, "w") as f:
        yaml.dump(registry, f, default_flow_style=False, sort_keys=False)

    report = BenchmarkReport(
        benchmark_date=datetime.now(timezone.utc).isoformat(),
        git_commit=None,
        dataset_version="golden_transactions_expanded.jsonl",
        model_name="LinkPredictor",
        model_version="v0.1",
        metrics=metrics,
        passed=all_pass,
    )
    write_report(report, str(REPORT_PATH))

    print(f"\n{'✓ ALL THRESHOLDS PASSED' if all_pass else '✗ SOME THRESHOLDS FAILED'}")
    if not all_pass:
        sys.exit(1)


if __name__ == "__main__":
    main()
