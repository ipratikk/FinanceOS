#!/usr/bin/env python3
"""
Train NarrationEmbedder v0.1 — sentence transformer for Indian financial narrations.

Architecture: paraphrase-multilingual-MiniLM-L12-v2 base + linear projection → Float32[128]
Loss: TripletMarginLoss(margin=0.3) on L2-normalized embeddings
Input: training/embedding/data/triplets.jsonl
Output: training/embedding/models/NarrationEmbedder_v0.1.pt
"""

import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import DataLoader, Dataset
from torch.optim import AdamW
from torch.optim.lr_scheduler import CosineAnnealingLR
from tqdm import tqdm

sys.path.insert(0, str(Path(__file__).parent.parent))
from benchmark_base import BenchmarkReport, write_report

TRIPLETS_PATH = Path(__file__).parent / "data" / "triplets.jsonl"
MODELS_DIR = Path(__file__).parent / "models"
CHECKPOINT_PATH = MODELS_DIR / "NarrationEmbedder_v0.1.pt"
REPORT_PATH = Path(__file__).parent.parent / "reports" / "embedding_training_metrics.json"

BASE_MODEL = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
EMBEDDING_DIM = 128
EPOCHS = 10
BATCH_SIZE = 32
LR = 2e-5
MARGIN = 0.3
RANDOM_SEED = 42


class TripletDataset(Dataset):
    def __init__(self, path: Path):
        self.triplets = []
        with open(path) as f:
            for line in f:
                if line.strip():
                    self.triplets.append(json.loads(line))

    def __len__(self):
        return len(self.triplets)

    def __getitem__(self, idx):
        t = self.triplets[idx]
        return t["anchor"], t["positive"], t["negative"]


class NarrationEmbedder(nn.Module):
    def __init__(self, base_model_name: str, output_dim: int):
        super().__init__()
        from sentence_transformers import SentenceTransformer
        self.encoder = SentenceTransformer(base_model_name)
        base_dim = self.encoder.get_embedding_dimension()
        self.projection = nn.Linear(base_dim, output_dim, bias=False)
        self.output_dim = output_dim

    def encode_texts(self, texts: list[str]) -> torch.Tensor:
        """Encode with gradient tracking — accesses transformer directly to avoid inference_mode."""
        features = self.encoder.preprocess(texts)
        device = next(self.parameters()).device
        features = {k: v.to(device) if hasattr(v, "to") else v for k, v in features.items()}
        out = self.encoder[0](features)
        out = self.encoder[1](out)
        embeddings = out["sentence_embedding"]
        projected = self.projection(embeddings)
        return F.normalize(projected, p=2, dim=-1)

    def encode_for_eval(self, texts: list[str]) -> torch.Tensor:
        """Encode without gradient tracking for evaluation."""
        with torch.no_grad():
            raw = self.encoder.encode(texts, show_progress_bar=False, convert_to_numpy=True)
            proj_device = self.projection.weight.device
            embeddings = torch.tensor(raw, dtype=torch.float32, device=proj_device)
            projected = self.projection(embeddings)
            return F.normalize(projected, p=2, dim=-1)

    def forward(self, texts: list[str]) -> torch.Tensor:
        return self.encode_texts(texts)


def train_epoch(model, loader, optimizer, device, epoch, total_epochs):
    model.train()
    total_loss = 0.0
    criterion = nn.TripletMarginWithDistanceLoss(
        distance_function=lambda a, b: 1 - F.cosine_similarity(a, b),
        margin=MARGIN,
    )
    pbar = tqdm(loader, desc=f"Epoch {epoch}/{total_epochs}", leave=False)
    for anchors, positives, negatives in pbar:
        optimizer.zero_grad()
        a_emb = model(list(anchors))
        p_emb = model(list(positives))
        n_emb = model(list(negatives))
        loss = criterion(a_emb, p_emb, n_emb)
        loss.backward()
        optimizer.step()
        total_loss += loss.item()
        pbar.set_postfix(loss=f"{loss.item():.4f}")
    return total_loss / len(loader)


def quick_eval(model, dataset, n_samples=200):
    """Compute fraction of triplets where d(a,p) < d(a,n)."""
    model.eval()
    indices = list(range(min(n_samples, len(dataset))))
    anchors = [dataset[i][0] for i in indices]
    positives = [dataset[i][1] for i in indices]
    negatives = [dataset[i][2] for i in indices]
    with torch.no_grad():
        a = model.encode_for_eval(anchors)
        p = model.encode_for_eval(positives)
        n = model.encode_for_eval(negatives)
        dp = 1 - F.cosine_similarity(a, p)
        dn = 1 - F.cosine_similarity(a, n)
        correct = (dp < dn).float().mean().item()
    return correct


def main():
    torch.manual_seed(RANDOM_SEED)
    MODELS_DIR.mkdir(parents=True, exist_ok=True)

    if not TRIPLETS_PATH.exists():
        print(f"✗ Triplets not found at {TRIPLETS_PATH}. Run generate_triplets.py first.")
        sys.exit(1)

    dataset = TripletDataset(TRIPLETS_PATH)
    print(f"✓ Loaded {len(dataset)} triplets")

    loader = DataLoader(dataset, batch_size=BATCH_SIZE, shuffle=True, num_workers=0)

    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"  Device: {device}")

    model = NarrationEmbedder(BASE_MODEL, EMBEDDING_DIM)
    model.to(device)

    optimizer = AdamW(model.parameters(), lr=LR)
    scheduler = CosineAnnealingLR(optimizer, T_max=EPOCHS)

    history = []
    start = time.time()
    for epoch in range(1, EPOCHS + 1):
        loss = train_epoch(model, loader, optimizer, device, epoch, EPOCHS)
        acc = quick_eval(model, dataset)
        scheduler.step()
        history.append({"epoch": epoch, "loss": round(loss, 4), "triplet_accuracy": round(acc, 4)})
        print(f"  Epoch {epoch:2d}/{EPOCHS} | loss={loss:.4f} | triplet_acc={acc:.4f}")

    elapsed = time.time() - start
    print(f"✓ Training complete in {elapsed:.1f}s")

    torch.save({
        "model_state_dict": model.state_dict(),
        "projection_state_dict": model.projection.state_dict(),
        "base_model": BASE_MODEL,
        "output_dim": EMBEDDING_DIM,
        "epochs": EPOCHS,
        "final_loss": history[-1]["loss"],
    }, CHECKPOINT_PATH)
    print(f"✓ Checkpoint saved → {CHECKPOINT_PATH}")

    report = BenchmarkReport(
        benchmark_date=datetime.now(timezone.utc).isoformat(),
        git_commit=None,
        dataset_version="golden_transactions_expanded.jsonl",
        model_name="NarrationEmbedder",
        model_version="v0.1",
        metrics={
            "epochs": EPOCHS,
            "final_loss": history[-1]["loss"],
            "final_triplet_accuracy": history[-1]["triplet_accuracy"],
            "training_time_seconds": round(elapsed, 1),
            "history": history,
            "hyperparameters": {
                "base_model": BASE_MODEL,
                "output_dim": EMBEDDING_DIM,
                "batch_size": BATCH_SIZE,
                "lr": LR,
                "margin": MARGIN,
            },
        },
        passed=True,
    )
    write_report(report, str(REPORT_PATH))


if __name__ == "__main__":
    main()
