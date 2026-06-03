#!/usr/bin/env python3
"""
Export NarrationEmbedder full pipeline to CoreML.

Pipeline: BERT → attention-masked mean-pool → Linear(384→128) → L2-normalize
Uses HuggingFace exporters (github.com/huggingface/exporters) for BertCoreMLConfig.
Uses WWDC20-documented register_torch_op to handle the 'int' cast op unsupported
in coremltools 9 with transformers 5.x.
Output: Float32[1,128] named "embedding"
"""

import hashlib
import sys
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
import yaml

sys.path.insert(0, str(Path(__file__).parent.parent))

CHECKPOINT_PATH = Path(__file__).parent / "models" / "NarrationEmbedder_v0.1.pt"
MLMODEL_PATH = Path(__file__).parent / "models" / "NarrationEmbedder_v0.1.mlmodel"
MLMODELC_PATH = Path(__file__).parent / "models" / "NarrationEmbedder_v0.1.mlmodelc"
MLMODELC_ZIP_PATH = Path(__file__).parent / "models" / "NarrationEmbedder_v0.1.mlmodelc.zip"
REGISTRY_PATH = Path(__file__).parent / "models" / "model_registry_entry.yaml"
SEQ_LEN = 64
EMBEDDING_DIM = 128
GITHUB_RELEASE_TAG = "models-v0.1"
GITHUB_REPO = "ipratikk/FinanceOS"


class FullEmbedder(nn.Module):
    """BERT + attention-masked mean-pool + projection + L2-norm → Float32[1,128]."""

    def __init__(self, bert_model, projection: nn.Linear):
        super().__init__()
        self.bert = bert_model
        self.projection = projection

    def forward(
        self,
        input_ids: torch.Tensor,       # Int32[1, SEQ_LEN]
        attention_mask: torch.Tensor,  # Int32[1, SEQ_LEN]
    ) -> torch.Tensor:
        token_type_ids = torch.zeros_like(input_ids)
        outputs = self.bert(
            input_ids=input_ids,
            attention_mask=attention_mask,
            token_type_ids=token_type_ids,
            return_dict=False,
        )
        hidden = outputs[0]  # [1, SEQ_LEN, 384]
        mask = attention_mask.unsqueeze(-1).float()  # [1, SEQ_LEN, 1]
        pooled = (hidden * mask).sum(dim=1) / mask.sum(dim=1).clamp(min=1e-9)  # [1, 384]
        projected = self.projection(pooled)  # [1, 128]
        return F.normalize(projected, p=2, dim=-1)  # [1, 128]


def compile_and_package(mlmodel_path: Path, mlmodelc_path: Path, zip_path: Path) -> str:
    """
    Compile .mlmodel → .mlmodelc via xcrun coremlc, then zip for distribution.
    Returns SHA256 of the zip.
    """
    import shutil
    import subprocess
    import zipfile

    if mlmodelc_path.exists():
        shutil.rmtree(mlmodelc_path)

    print("✓ Compiling .mlmodel → .mlmodelc...")
    result = subprocess.run(
        ["xcrun", "coremlc", "compile", str(mlmodel_path), str(mlmodel_path.parent)],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"coremlc compile failed:\n{result.stderr}")
    print(f"  Compiled → {mlmodelc_path.name}")

    print("✓ Zipping .mlmodelc...")
    if zip_path.exists():
        zip_path.unlink()
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for file in sorted(mlmodelc_path.rglob("*")):
            zf.write(file, file.relative_to(mlmodelc_path.parent))

    zip_mb = zip_path.stat().st_size / (1024 * 1024)
    print(f"  Zipped → {zip_path.name} ({zip_mb:.1f} MB)")
    return compute_sha256(zip_path)


def upload_to_github_release(zip_path: Path, tag: str, repo: str) -> str:
    """
    Create or update a GitHub Release and upload the zip asset.
    Returns the asset download URL.
    Requires: gh CLI authenticated.
    """
    import subprocess

    asset_name = zip_path.name
    download_url = f"https://github.com/{repo}/releases/download/{tag}/{asset_name}"

    # Check if release exists
    check = subprocess.run(
        ["gh", "release", "view", tag, "--repo", repo],
        capture_output=True, text=True,
    )
    if check.returncode != 0:
        print(f"  Creating release {tag}...")
        subprocess.run(
            ["gh", "release", "create", tag,
             "--repo", repo,
             "--title", f"ML Models {tag}",
             "--notes", "NarrationEmbedder v0.1 — CoreML NeuralNetwork (BERT + mean-pool + projection + L2-norm)",
             "--prerelease"],
            check=True, capture_output=True,
        )
    else:
        print(f"  Release {tag} already exists — uploading asset...")

    # Delete existing asset if present, then upload
    subprocess.run(
        ["gh", "release", "delete-asset", tag, asset_name, "--repo", repo, "--yes"],
        capture_output=True,
    )
    subprocess.run(
        ["gh", "release", "upload", tag, str(zip_path), "--repo", repo, "--clobber"],
        check=True,
    )
    print(f"  Uploaded → {download_url}")
    return download_url


def compute_sha256(path: Path) -> str:
    sha = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            sha.update(chunk)
    return sha.hexdigest()


def register_missing_ops():
    """
    Register composite op handlers for ops unsupported in coremltools 9 with
    transformers 5.x, using the WWDC20-documented register_torch_op mechanism.

    Fixes:
      'int'      — _cast() calls int(x.val) on a numpy array; fix via .item()
      'new_ones' — missing from coremltools 9; mirrors the existing new_zeros impl
    """
    from coremltools.converters.mil import Builder as mb
    from coremltools.converters.mil.frontend.torch.torch_op_registry import (
        _TORCH_OPS_REGISTRY,
    )
    from coremltools.converters.mil.frontend.torch.ops import _get_inputs

    def _int_fixed(context, node):
        inputs = _get_inputs(context, node, expected=1)
        x = inputs[0]
        if not (len(x.shape) == 0 or all(d == 1 for d in x.shape)):
            raise ValueError("int cast: input must be scalar or length-1 tensor")
        if x.can_be_folded_to_const():
            val = x.val
            if hasattr(val, "item"):
                val = val.item()
            res = mb.const(val=int(val), name=node.name)
        elif len(x.shape) > 0:
            squeezed = mb.squeeze(x=x, name=node.name + "_squeeze")
            res = mb.cast(x=squeezed, dtype="int32", name=node.name)
        else:
            res = mb.cast(x=x, dtype="int32", name=node.name)
        context.add(res, node.name)

    def _new_ones(context, node):
        # Mirrors coremltools new_zeros (ops.py) — fill with 1 instead of 0
        inputs = _get_inputs(context, node)
        shape = inputs[1]
        if isinstance(shape, list):
            shape = mb.concat(values=shape, axis=0)
        context.add(mb.fill(shape=shape, value=1.0, name=node.name))

    _TORCH_OPS_REGISTRY["int"] = _int_fixed
    _TORCH_OPS_REGISTRY["new_ones"] = _new_ones
    print("  Registered: 'int' cast fix, 'new_ones'")


def main():
    try:
        import coremltools as ct

        # exporters 0.0.1 expects transformers 4.x — patch missing symbols before import
        import transformers.utils as _tu
        if not hasattr(_tu, "is_tf_available"):
            _tu.is_tf_available = lambda: False
        if not hasattr(_tu, "is_flax_available"):
            _tu.is_flax_available = lambda: False

        from exporters.coreml.models import BertCoreMLConfig
        from exporters.coreml.convert import get_input_types
        from transformers import AutoModel, AutoTokenizer
        from transformers.utils import TensorType
    except ImportError as e:
        print(f"✗ Missing dependency: {e}")
        print("  Run: pip install coremltools 'git+https://github.com/huggingface/exporters.git'")
        sys.exit(1)

    if not CHECKPOINT_PATH.exists():
        print(f"✗ Checkpoint not found: {CHECKPOINT_PATH}")
        print("  Run: python train.py")
        sys.exit(1)

    print("✓ Loading checkpoint...")
    checkpoint = torch.load(CHECKPOINT_PATH, map_location="cpu", weights_only=False)
    base_model_name = checkpoint["base_model"]
    output_dim = checkpoint["output_dim"]
    print(f"  Base model: {base_model_name}")
    print(f"  Output dim: {output_dim}")

    print("✓ Loading BERT + tokenizer...")
    bert = AutoModel.from_pretrained(base_model_name)
    tokenizer = AutoTokenizer.from_pretrained(base_model_name)
    bert.eval()
    base_dim = bert.config.hidden_size
    print(f"  Hidden size: {base_dim}")

    print("✓ Loading projection weights...")
    projection = nn.Linear(base_dim, output_dim, bias=False)
    projection.load_state_dict(checkpoint["projection_state_dict"])
    projection.eval()

    model = FullEmbedder(bert, projection)
    model.eval()

    print("✓ Building dummy inputs via BertCoreMLConfig...")
    bert_cfg = BertCoreMLConfig(bert.config, task="feature-extraction", use_past=False)
    dummy = bert_cfg.generate_dummy_inputs(tokenizer, framework=TensorType.PYTORCH)
    input_ids = dummy["input_ids"][0][:, :SEQ_LEN]
    attn_mask = dummy["attention_mask"][0][:, :SEQ_LEN]

    if input_ids.shape[1] < SEQ_LEN:
        pad = SEQ_LEN - input_ids.shape[1]
        input_ids = F.pad(input_ids, (0, pad), value=tokenizer.pad_token_id or 0)
        attn_mask = F.pad(attn_mask, (0, pad), value=0)

    print(f"  Input shape: {input_ids.shape}")

    print("✓ Smoke-testing pipeline...")
    with torch.no_grad():
        ref_out = model(input_ids, attn_mask)
    assert ref_out.shape == (1, EMBEDDING_DIM)
    assert abs(float(torch.norm(ref_out)) - 1.0) < 1e-4
    print(f"  Output shape: {ref_out.shape}, norm: {float(torch.norm(ref_out)):.6f} ✓")

    print("✓ JIT tracing...")
    with torch.no_grad():
        traced = torch.jit.trace(model, (input_ids, attn_mask), strict=True)
    print("  Trace complete")

    print("✓ Registering composite ops (WWDC20 pattern)...")
    register_missing_ops()

    print("✓ Converting to CoreML (NeuralNetwork format)...")
    input_types = [
        ct.TensorType(name="input_ids", shape=ct.Shape([1, SEQ_LEN]), dtype=np.int32),
        ct.TensorType(name="attention_mask", shape=ct.Shape([1, SEQ_LEN]), dtype=np.int32),
    ]
    mlmodel = ct.convert(
        traced,
        inputs=input_types,
        outputs=[ct.TensorType(name="embedding", dtype=np.float32)],
        convert_to="neuralnetwork",
        compute_units=ct.ComputeUnit.ALL,
    )

    print("✓ Saving .mlmodel...")
    MLMODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    mlmodel.save(str(MLMODEL_PATH))

    size_mb = MLMODEL_PATH.stat().st_size / (1024 * 1024)
    sha256 = compute_sha256(MLMODEL_PATH)
    print(f"  Saved → {MLMODEL_PATH.name} ({size_mb:.1f} MB)")
    print(f"  SHA256: {sha256[:16]}...")

    print("✓ Verifying CoreML model output...")
    loaded = ct.models.MLModel(str(MLMODEL_PATH))
    result = loaded.predict({
        "input_ids": input_ids.numpy().astype(np.int32),
        "attention_mask": attn_mask.numpy().astype(np.int32),
    })
    cml_out = result["embedding"]
    max_diff = float(np.max(np.abs(cml_out - ref_out.numpy())))
    # NeuralNetwork format uses float16 internally — up to ~2e-3 delta is expected
    status = "✓" if max_diff < 2e-3 else "✗ MISMATCH"
    print(f"  Max delta (CoreML vs PyTorch): {max_diff:.6f} {status}")

    # Compile + package for on-demand distribution
    zip_sha256 = compile_and_package(MLMODEL_PATH, MLMODELC_PATH, MLMODELC_ZIP_PATH)
    zip_mb = MLMODELC_ZIP_PATH.stat().st_size / (1024 * 1024)

    # Upload to GitHub Release
    download_url = upload_to_github_release(MLMODELC_ZIP_PATH, GITHUB_RELEASE_TAG, GITHUB_REPO)

    print("✓ Writing registry entry...")
    registry = {
        "model_name": "NarrationEmbedder",
        "model_version": "v0.1",
        "export_date": datetime.now(timezone.utc).isoformat(),
        "base_model": base_model_name,
        "format": "CoreML NeuralNetwork",
        "distribution": "on-demand (GitHub Release)",
        "download_url": download_url,
        "artifacts": {
            "mlmodel": {
                "file": MLMODEL_PATH.name,
                "sha256": sha256,
                "size_mb": round(size_mb, 2),
            },
            "mlmodelc_zip": {
                "file": MLMODELC_ZIP_PATH.name,
                "sha256": zip_sha256,
                "size_mb": round(zip_mb, 2),
                "download_url": download_url,
            },
        },
        "pipeline": {
            "inputs": [
                {"name": "input_ids", "shape": [1, SEQ_LEN], "dtype": "Int32"},
                {"name": "attention_mask", "shape": [1, SEQ_LEN], "dtype": "Int32"},
            ],
            "output": {"name": "embedding", "shape": [1, EMBEDDING_DIM], "dtype": "Float32"},
            "stages": ["BERT", "attention-masked-mean-pool", "linear-384→128", "L2-normalize"],
        },
    }
    with open(REGISTRY_PATH, "w") as f:
        yaml.dump(registry, f, default_flow_style=False, sort_keys=False)
    print(f"  Registry → {REGISTRY_PATH.name}")

    print(f"\n✓ Export complete")
    print(f"  .mlmodel: {size_mb:.1f} MB")
    print(f"  .mlmodelc.zip: {zip_mb:.1f} MB")
    print(f"  Download URL: {download_url}")


if __name__ == "__main__":
    main()
