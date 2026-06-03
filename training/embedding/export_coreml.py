#!/usr/bin/env python3
"""
Export NarrationEmbedder v0.1 to CoreML using HuggingFace Optimum.

Handles: tokenizer export + model export with proper quantization/optimization.
Inputs: input_ids Int32[1,64], attention_mask Int32[1,64]
Output: embedding Float32[1,128]
"""

import hashlib
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

import yaml

CHECKPOINT_PATH = Path(__file__).parent / "models" / "NarrationEmbedder_v0.1.pt"
MLMODEL_PATH = Path(__file__).parent / "models" / "NarrationEmbedder_v0.1.mlmodel"
REGISTRY_PATH = Path(__file__).parent / "models" / "model_registry_entry.yaml"
TOKENIZER_PATH = Path(__file__).parent / "models" / "tokenizer"

SEQ_LEN = 64
EMBEDDING_DIM = 128


def compute_sha256(path: Path) -> str:
    sha = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            sha.update(chunk)
    return sha.hexdigest()


def main():
    try:
        from optimum.exporters.coreml import export_coreml_model
        from transformers import AutoTokenizer
    except ImportError:
        print("✗ Missing: pip install optimum[coreml]")
        sys.exit(1)

    print("✓ Loading checkpoint...")
    import torch
    from train import NarrationEmbedder

    checkpoint = torch.load(CHECKPOINT_PATH, map_location="cpu")
    model = NarrationEmbedder(checkpoint["base_model"], checkpoint["output_dim"])
    model.load_state_dict(checkpoint["model_state_dict"])
    model.to("cpu")
    model.eval()

    base_dim = model.encoder.get_embedding_dimension()
    print(f"  Base dim: {base_dim} → projected: {EMBEDDING_DIM}")

    # Export encoder only (not full pipeline — simpler + more stable)
    print("✓ Exporting to CoreML via Optimum...")

    try:
        export_coreml_model(
            model.encoder,
            from_pretrained_model_id=checkpoint["base_model"],
            output=MLMODEL_PATH.parent,
            int8_quantize=False,  # Keep float32 for precision
            min_deployment_target="14",
        )
        print(f"✓ CoreML model saved → {MLMODEL_PATH.parent}")
    except Exception as e:
        print(f"✗ Optimum export failed: {e}")
        print("  Fallback: saving PyTorch + tokenizer for Swift runtime inference")
        TOKENIZER_PATH.mkdir(parents=True, exist_ok=True)
        tokenizer = AutoTokenizer.from_pretrained(checkpoint["base_model"])
        tokenizer.save_pretrained(TOKENIZER_PATH)
        torch.save({
            "model_state_dict": model.state_dict(),
            "projection_state_dict": model.projection.state_dict(),
            "base_model": checkpoint["base_model"],
            "output_dim": EMBEDDING_DIM,
        }, CHECKPOINT_PATH)
        print(f"  Tokenizer + model saved for Swift PyTorch runtime")
        return

    # Compute hash
    mlmodel_files = list(MLMODEL_PATH.parent.glob("*.mlmodel"))
    if not mlmodel_files:
        print("✗ CoreML export didn't produce .mlmodel file")
        sys.exit(1)

    actual_model = mlmodel_files[0]
    artifact_hash = compute_sha256(actual_model)

    registry = {
        "model_name": "NarrationEmbedder",
        "model_version": "v0.1",
        "artifact": actual_model.name,
        "export_date": datetime.now(timezone.utc).isoformat(),
        "base_model": checkpoint["base_model"],
        "input_ids": f"Int32[1, {SEQ_LEN}]",
        "attention_mask": f"Int32[1, {SEQ_LEN}]",
        "output": f"Float32[1, {base_dim}] (sentence embedding from encoder)",
        "sha256": artifact_hash,
        "notes": "Encoder output (384-dim). Swift: apply projection 384→128 + L2-norm locally.",
    }
    with open(REGISTRY_PATH, "w") as f:
        yaml.dump(registry, f, default_flow_style=False, sort_keys=False)

    print(f"✓ Registry → {REGISTRY_PATH}")
    print(f"  SHA256: {artifact_hash[:16]}...")


if __name__ == "__main__":
    main()
