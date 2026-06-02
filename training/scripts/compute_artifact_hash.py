#!/usr/bin/env python3
"""
Compute SHA256 hash of CoreML model artifacts for model_registry.yaml.

CoreML .mlpackage files are directories containing multiple files.
Hash all files deterministically (sorted by name).

Usage:
  python compute_artifact_hash.py artifacts/CategoryClassifier_v1.2.mlpackage
"""

import hashlib
import sys
from pathlib import Path


def sha256_of_directory(path: Path) -> str:
    """Hash all files in directory deterministically (sorted)."""
    h = hashlib.sha256()
    for f in sorted(path.rglob("*")):
        if f.is_file():
            h.update(f.read_bytes())
    return h.hexdigest()


def sha256_of_file(path: Path) -> str:
    """Hash single file."""
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    if len(sys.argv) < 2:
        print("Usage: python compute_artifact_hash.py <artifact_path>")
        sys.exit(1)

    artifact_path = Path(sys.argv[1])

    if not artifact_path.exists():
        print(f"Error: {artifact_path} not found", file=sys.stderr)
        sys.exit(1)

    if artifact_path.is_dir():
        hash_value = sha256_of_directory(artifact_path)
    else:
        hash_value = sha256_of_file(artifact_path)

    print(f"{artifact_path.name}: {hash_value}")
    print(f"\nCopy to model_registry.yaml:")
    print(f"  artifact_sha256: \"{hash_value}\"")


if __name__ == "__main__":
    main()
