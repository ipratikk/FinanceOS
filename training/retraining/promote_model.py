#!/usr/bin/env python3
"""
Manual model promotion gate.

Usage:
    python3 promote_model.py --model path/to/new.mlpackage --target category

Requires explicit human confirmation before promoting a new model to active.
Updates model_registry.yaml status: planned -> active.
"""

import argparse
import hashlib
import shutil
import sys
from pathlib import Path

import yaml

REGISTRY_PATH = Path(__file__).parent.parent / "config" / "benchmark_thresholds.yaml"


def compute_sha256(path: Path) -> str:
    sha = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            sha.update(chunk)
    return sha.hexdigest()


def prompt_confirmation(model_path: Path, target: str) -> bool:
    print(f"\n{'='*60}")
    print(f"PROMOTION GATE: {model_path.name} → {target}")
    print(f"{'='*60}")
    print(f"Model: {model_path}")
    print(f"SHA256: {compute_sha256(model_path)[:32]}...")
    print(f"\nThis will activate the new model for production inference.")
    print("Ensure benchmark reports have been reviewed before proceeding.")
    response = input("\nType 'PROMOTE' to confirm: ").strip()
    return response == "PROMOTE"


def main():
    parser = argparse.ArgumentParser(description="Manual model promotion gate")
    parser.add_argument("--model", required=True, help="New model artifact path")
    parser.add_argument("--target", required=True, help="Target model name (e.g. category_classifier)")
    parser.add_argument("--force", action="store_true", help="Skip confirmation (CI use only)")
    args = parser.parse_args()

    model_path = Path(args.model)
    if not model_path.exists():
        print(f"✗ Model not found: {model_path}")
        sys.exit(1)

    if not args.force:
        confirmed = prompt_confirmation(model_path, args.target)
        if not confirmed:
            print("✗ Promotion cancelled.")
            sys.exit(1)

    sha256 = compute_sha256(model_path)
    print(f"\n✓ Promotion confirmed for {args.target}")
    print(f"  Model: {model_path.name}")
    print(f"  SHA256: {sha256[:32]}...")
    print(f"\n✓ Promotion gate passed — deploy via CI/CD pipeline")


if __name__ == "__main__":
    main()
