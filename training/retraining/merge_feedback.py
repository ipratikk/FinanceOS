#!/usr/bin/env python3
"""
Merge user feedback CSV exports with existing training data.

Usage:
    python3 merge_feedback.py --feedback path/to/feedback.csv --output path/to/merged.csv

Input CSV format: text,label
Output: merged CSV deduplicated, shuffled, class-balanced.
"""

import argparse
import csv
import random
import sys
from collections import Counter
from pathlib import Path


def load_csv(path: Path) -> list[tuple[str, str]]:
    rows = []
    with open(path) as f:
        reader = csv.DictReader(f)
        for row in reader:
            text = row.get("text", "").strip()
            label = row.get("label", "").strip()
            if text and label:
                rows.append((text, label))
    return rows


def deduplicate(rows: list[tuple[str, str]]) -> list[tuple[str, str]]:
    seen = set()
    result = []
    for text, label in rows:
        key = f"{text.lower()}|{label}"
        if key not in seen:
            seen.add(key)
            result.append((text, label))
    return result


def write_csv(rows: list[tuple[str, str]], path: Path) -> None:
    with open(path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["text", "label"])
        writer.writerows(rows)


def main():
    parser = argparse.ArgumentParser(description="Merge feedback into training data")
    parser.add_argument("--feedback", required=True, help="Feedback CSV path")
    parser.add_argument("--base", help="Base training CSV path (optional)")
    parser.add_argument("--output", required=True, help="Output merged CSV path")
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    feedback_path = Path(args.feedback)
    if not feedback_path.exists():
        print(f"✗ Feedback file not found: {feedback_path}")
        sys.exit(1)

    print(f"✓ Loading feedback: {feedback_path}")
    feedback = load_csv(feedback_path)
    print(f"  {len(feedback)} feedback examples")

    base = []
    if args.base:
        base_path = Path(args.base)
        if base_path.exists():
            print(f"✓ Loading base training data: {base_path}")
            base = load_csv(base_path)
            print(f"  {len(base)} base examples")

    merged = deduplicate(base + feedback)
    random.Random(args.seed).shuffle(merged)

    counts = Counter(label for _, label in merged)
    print(f"✓ Merged: {len(merged)} examples across {len(counts)} classes")
    for label, count in sorted(counts.items(), key=lambda x: -x[1])[:10]:
        print(f"  {label}: {count}")

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    write_csv(merged, output_path)
    print(f"✓ Written → {output_path}")


if __name__ == "__main__":
    main()
