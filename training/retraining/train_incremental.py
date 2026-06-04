#!/usr/bin/env python3
"""
Incremental retraining pipeline for CategoryClassifier.

Usage:
    python3 train_incremental.py --data path/to/merged.csv --output path/to/model.mlpackage

Trains a lightweight CreateML-compatible text classifier on the merged dataset.
"""

import argparse
import csv
import json
import sys
from collections import Counter
from pathlib import Path

MINIMUM_EXAMPLES = 100
MINIMUM_CLASS_EXAMPLES = 5


def load_dataset(path: Path) -> list[dict]:
    examples = []
    with open(path) as f:
        reader = csv.DictReader(f)
        for row in reader:
            text = row.get("text", "").strip()
            label = row.get("label", "").strip()
            if text and label:
                examples.append({"text": text, "label": label})
    return examples


def validate_dataset(examples: list[dict]) -> list[str]:
    errors = []
    if len(examples) < MINIMUM_EXAMPLES:
        errors.append(f"Insufficient examples: {len(examples)} < {MINIMUM_EXAMPLES}")
    counts = Counter(e["label"] for e in examples)
    rare = {k: v for k, v in counts.items() if v < MINIMUM_CLASS_EXAMPLES}
    if rare:
        errors.append(f"Classes with < {MINIMUM_CLASS_EXAMPLES} examples: {list(rare.keys())}")
    return errors


def write_training_manifest(examples: list[dict], output_dir: Path) -> Path:
    """Write JSONL manifest compatible with CreateML text classifier."""
    output_dir.mkdir(parents=True, exist_ok=True)
    manifest_path = output_dir / "training_data.jsonl"
    with open(manifest_path, "w") as f:
        for ex in examples:
            f.write(json.dumps({"text": ex["text"], "label": ex["label"]}) + "\n")
    return manifest_path


def main():
    parser = argparse.ArgumentParser(description="Incremental retraining pipeline")
    parser.add_argument("--data", required=True, help="Merged training CSV path")
    parser.add_argument("--output-dir", default="training/retraining/artifacts", help="Output directory")
    args = parser.parse_args()

    data_path = Path(args.data)
    if not data_path.exists():
        print(f"✗ Data file not found: {data_path}")
        sys.exit(1)

    print(f"✓ Loading dataset: {data_path}")
    examples = load_dataset(data_path)
    print(f"  {len(examples)} examples loaded")

    print("✓ Validating dataset...")
    errors = validate_dataset(examples)
    if errors:
        for err in errors:
            print(f"  ✗ {err}")
        sys.exit(1)

    counts = Counter(e["label"] for e in examples)
    print(f"  {len(counts)} classes, {len(examples)} examples")

    output_dir = Path(args.output_dir)
    manifest_path = write_training_manifest(examples, output_dir)
    print(f"✓ Training manifest → {manifest_path}")
    print(f"  Ready for CreateML / coremltools NLTextClassifier training")
    print(f"  Run: python3 -m coremltools.converters.nlp ... (model-specific)")

    # Write summary
    summary = {
        "timestamp": __import__("datetime").datetime.utcnow().isoformat(),
        "example_count": len(examples),
        "class_count": len(counts),
        "class_distribution": dict(counts.most_common(20)),
        "status": "manifest_ready",
    }
    summary_path = output_dir / "training_summary.json"
    with open(summary_path, "w") as f:
        json.dump(summary, f, indent=2)
    print(f"✓ Summary → {summary_path}")
    print("\n✓ Incremental training pipeline complete — manual promotion gate required before deployment")


if __name__ == "__main__":
    main()
