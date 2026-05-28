"""
PyTorch text classifier → CoreML export.
Uses torch.nn + torchtext for text classification.
Exports to .mlmodel via coremltools (full support for PyTorch models).

Usage:
    python train_pytorch.py --data fixtures/sample_transactions.csv --output models/
"""

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

import coremltools as ct
import numpy as np
import pandas as pd
import torch
import torch.nn as nn
from sklearn.metrics import accuracy_score, f1_score
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from torch.utils.data import DataLoader, TensorDataset


def load_and_filter(path: str) -> pd.DataFrame:
    df = pd.read_csv(path)
    df = df[df["user_category"].notna()].copy()
    df = df[df["raw_description"].notna()].copy()
    df["raw_description"] = df["raw_description"].astype(str).str.strip()
    return df


class TextClassifier(nn.Module):
    """Simple text classifier: embedding → pooling → linear → softmax."""
    def __init__(self, vocab_size, embedding_dim, num_classes):
        super().__init__()
        self.embedding = nn.Embedding(vocab_size, embedding_dim)
        self.fc = nn.Linear(embedding_dim, num_classes)

    def forward(self, x):
        embedded = self.embedding(x)
        pooled = torch.mean(embedded, dim=1)
        return self.fc(pooled)


def simple_tokenize(text, vocab):
    """Naive tokenizer: split on whitespace, map to vocab indices."""
    tokens = text.lower().split()
    return [vocab.get(t, vocab.get("<UNK>", 0)) for t in tokens]


def train_pytorch(data_path: str, output_dir: str) -> None:
    output = Path(output_dir)
    output.mkdir(parents=True, exist_ok=True)
    (output / "evaluation").mkdir(exist_ok=True)

    print("Loading data...")
    df = load_and_filter(data_path)
    print(f"  Labeled rows: {len(df)}")

    # Prepare labels
    le = LabelEncoder()
    y = le.fit_transform(df["user_category"])
    classes = le.classes_.tolist()
    num_classes = len(classes)

    # Build vocabulary
    texts = (df["raw_description"].str.lower() + " " + 
             df.get("canonical_merchant", "").fillna("").str.lower()).tolist()
    vocab = {"<PAD>": 0, "<UNK>": 1}
    for text in texts:
        for word in text.split():
            if word not in vocab:
                vocab[word] = len(vocab)
    vocab_size = len(vocab)

    # Tokenize
    X = [simple_tokenize(t, vocab) for t in texts]
    max_len = max(len(x) for x in X) if X else 10
    X_padded = np.array([x + [0] * (max_len - len(x)) for x in X])[:, :max_len]

    # Train/test split
    X_train, X_test, y_train, y_test = train_test_split(
        X_padded, y, test_size=0.2, random_state=42, stratify=None
    )

    # Train PyTorch model
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    model = TextClassifier(vocab_size=vocab_size, embedding_dim=32, num_classes=num_classes)
    model.to(device)

    optimizer = torch.optim.Adam(model.parameters(), lr=0.001)
    loss_fn = nn.CrossEntropyLoss()

    print("Training PyTorch model...")
    for epoch in range(10):
        X_tensor = torch.LongTensor(X_train).to(device)
        y_tensor = torch.LongTensor(y_train).to(device)
        
        optimizer.zero_grad()
        logits = model(X_tensor)
        loss = loss_fn(logits, y_tensor)
        loss.backward()
        optimizer.step()

        if epoch % 3 == 0:
            print(f"  Epoch {epoch}: loss={loss.item():.4f}")

    # Evaluate
    model.eval()
    with torch.no_grad():
        X_test_tensor = torch.LongTensor(X_test).to(device)
        logits = model(X_test_tensor)
        y_pred = logits.argmax(dim=1).cpu().numpy()

    acc = accuracy_score(y_test, y_pred)
    macro_f1 = f1_score(y_test, y_pred, average="macro", zero_division=0)
    print(f"  Test Accuracy: {acc:.4f}, Macro F1: {macro_f1:.4f}")

    # Export to CoreML
    print("Exporting to CoreML...")
    traced_model = torch.jit.trace(model, torch.zeros(1, max_len, dtype=torch.long).to(device))
    mlmodel = ct.convert(
        traced_model,
        convert_to="mlprogram",
        inputs=[ct.TensorType(name="input", shape=(1, max_len))],
        classifier_config=ct.ClassifierConfig(class_labels=classes),
    )

    mlmodel.short_description = "FinanceOS Transaction Category Classifier (PyTorch)"
    mlmodel.version = f"pytorch-{datetime.now(timezone.utc).strftime('%Y%m%d')}"
    mlmodel.author = "FinanceOS Intelligence Pipeline"

    model_path = output / "TransactionCategoryClassifier.mlmodel"
    mlmodel.save(str(model_path))
    print(f"  ✓ Model saved: {model_path}")

    # Save metrics
    metrics = {
        "accuracy": float(acc),
        "macro_f1": float(macro_f1),
        "model_type": "pytorch",
        "vocab_size": vocab_size,
        "embedding_dim": 32,
        "max_sequence_length": max_len,
    }
    metrics_path = output / "evaluation" / "category_metrics.json"
    with open(metrics_path, "w") as f:
        json.dump(metrics, f, indent=2)
    print(f"  ✓ Metrics saved: {metrics_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", default="fixtures/sample_transactions.csv")
    parser.add_argument("--output", default="models/")
    args = parser.parse_args()
    train_pytorch(args.data, args.output)
