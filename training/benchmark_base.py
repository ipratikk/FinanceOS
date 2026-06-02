#!/usr/bin/env python3
"""
Base benchmark module for FinanceOS Intelligence models.

Provides common utilities for loading golden dataset, computing metrics,
and generating JSON reports per doc 008-benchmark-plan schema.
"""

import json
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional
from datetime import datetime
from collections import defaultdict
from dataclasses import dataclass, asdict

@dataclass
class BenchmarkReport:
    """Benchmark report structure per doc 008 schema."""
    benchmark_date: str
    git_commit: Optional[str]
    dataset_version: str
    model_name: str
    model_version: str
    metrics: Dict[str, Any]
    passed: bool
    notes: Optional[str] = None

class GoldenDatasetLoader:
    """Load and parse golden_transactions.jsonl."""

    def __init__(self, filepath: str):
        self.filepath = Path(filepath)
        self.transactions = []
        self.load()

    def load(self):
        """Load JSONL file."""
        if not self.filepath.exists():
            raise FileNotFoundError(f"Golden dataset not found: {self.filepath}")

        with open(self.filepath) as f:
            for line in f:
                if line.strip():
                    self.transactions.append(json.loads(line))

        print(f"✓ Loaded {len(self.transactions)} golden transactions")

    def get_by_label(self, field: str, value: str) -> List[Dict]:
        """Get transactions by label value."""
        return [t for t in self.transactions if t.get("labels", {}).get(field) == value]

    def get_by_category(self, category: str) -> List[Dict]:
        """Get transactions by category."""
        return self.get_by_label("category", category)

    def get_by_intent(self, intent: str) -> List[Dict]:
        """Get transactions by intent."""
        return self.get_by_label("intent", intent)

    def distribution(self, field: str) -> Dict[str, int]:
        """Get distribution of label values."""
        dist = defaultdict(int)
        for t in self.transactions:
            value = t.get("labels", {}).get(field)
            if value:
                dist[value] += 1
        return dict(sorted(dist.items(), key=lambda x: -x[1]))

class MetricsComputer:
    """Compute standard ML metrics."""

    @staticmethod
    def accuracy(predictions: List[str], ground_truth: List[str]) -> float:
        """Compute accuracy (fraction of correct predictions)."""
        if not predictions or not ground_truth:
            return 0.0
        correct = sum(1 for p, g in zip(predictions, ground_truth) if p == g)
        return correct / len(predictions)

    @staticmethod
    def precision_recall_f1(
        predictions: List[str],
        ground_truth: List[str],
        labels: Optional[List[str]] = None,
    ) -> Dict[str, Dict[str, float]]:
        """Compute per-class and macro metrics."""

        if not labels:
            labels = list(set(ground_truth + predictions))

        per_class = {}
        for label in sorted(labels):
            tp = sum(1 for p, g in zip(predictions, ground_truth) if p == label and g == label)
            fp = sum(1 for p, g in zip(predictions, ground_truth) if p == label and g != label)
            fn = sum(1 for p, g in zip(predictions, ground_truth) if p != label and g == label)

            precision = tp / (tp + fp) if (tp + fp) > 0 else 0.0
            recall = tp / (tp + fn) if (tp + fn) > 0 else 0.0
            f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0.0

            per_class[label] = {
                "precision": round(precision, 4),
                "recall": round(recall, 4),
                "f1": round(f1, 4),
                "support": tp + fn,
            }

        # Macro averages
        macro_precision = sum(m["precision"] for m in per_class.values()) / len(per_class) if per_class else 0.0
        macro_recall = sum(m["recall"] for m in per_class.values()) / len(per_class) if per_class else 0.0
        macro_f1 = sum(m["f1"] for m in per_class.values()) / len(per_class) if per_class else 0.0

        return {
            "per_class": per_class,
            "macro": {
                "precision": round(macro_precision, 4),
                "recall": round(macro_recall, 4),
                "f1": round(macro_f1, 4),
            },
        }

    @staticmethod
    def confusion_matrix(predictions: List[str], ground_truth: List[str]) -> Dict[str, Dict[str, int]]:
        """Compute confusion matrix."""
        labels = sorted(set(ground_truth + predictions))
        matrix = {label: {l: 0 for l in labels} for label in labels}

        for p, g in zip(predictions, ground_truth):
            matrix[g][p] += 1

        return matrix

def write_report(report: BenchmarkReport, output_path: str):
    """Write JSON report."""
    output = Path(output_path)
    output.parent.mkdir(parents=True, exist_ok=True)

    with open(output, "w") as f:
        json.dump(asdict(report), f, indent=2)

    print(f"✓ Report written: {output}")
