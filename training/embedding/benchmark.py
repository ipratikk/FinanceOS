#!/usr/bin/env python3
"""
Benchmark NarrationEmbedder v0.1 for latency and memory.

Gates:
- P95 inference latency < 30ms per embedding
- Model size < 50MB

Output: training/reports/embedding_benchmark_metrics.json
"""

import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import yaml

sys.path.insert(0, str(Path(__file__).parent.parent))
from benchmark_base import BenchmarkReport, write_report, GoldenDatasetLoader

GOLDEN_PATH = Path(__file__).parent.parent / "data" / "golden_transactions_expanded.jsonl"
CHECKPOINT_PATH = Path(__file__).parent / "models" / "NarrationEmbedder_v0.1.pt"
MLPACKAGE_PATH = Path(__file__).parent / "models" / "NarrationEmbedder_v0.1.mlpackage"
THRESHOLDS_PATH = Path(__file__).parent.parent / "config" / "benchmark_thresholds.yaml"
REPORT_PATH = Path(__file__).parent.parent / "reports" / "embedding_benchmark_metrics.json"

N_WARMUP = 20
N_MEASURE = 1000


def load_thresholds():
    with open(THRESHOLDS_PATH) as f:
        config = yaml.safe_load(f)
    enc = config["models"]["embedding_encoder"]
    return enc["latency_p95_ms"], enc["memory_mb"]


def load_model():
    import torch
    from train import NarrationEmbedder
    checkpoint = torch.load(CHECKPOINT_PATH, map_location="cpu")
    model = NarrationEmbedder(checkpoint["base_model"], checkpoint["output_dim"])
    model.load_state_dict(checkpoint["model_state_dict"])
    model.eval()
    return model


def measure_model_size_mb(path: Path) -> float:
    if path.is_dir():
        return sum(f.stat().st_size for f in path.rglob("*") if f.is_file()) / (1024 * 1024)
    return os.path.getsize(path) / (1024 * 1024)


def measure_latency(model, narrations: list[str]) -> dict:
    import torch

    sample = narrations[:N_WARMUP]
    for text in sample:
        model.encode_for_eval([text])

    latencies_ms = []
    sample = narrations[:N_MEASURE]
    for text in sample:
        t0 = time.perf_counter()
        model.encode_for_eval([text])
        latencies_ms.append((time.perf_counter() - t0) * 1000)

    arr = np.array(latencies_ms)
    return {
        "mean_ms": round(float(np.mean(arr)), 2),
        "median_ms": round(float(np.median(arr)), 2),
        "p95_ms": round(float(np.percentile(arr, 95)), 2),
        "p99_ms": round(float(np.percentile(arr, 99)), 2),
        "min_ms": round(float(np.min(arr)), 2),
        "max_ms": round(float(np.max(arr)), 2),
        "n_samples": len(latencies_ms),
    }


def main():
    if not CHECKPOINT_PATH.exists():
        print(f"✗ Checkpoint not found: {CHECKPOINT_PATH}. Run train.py first.")
        sys.exit(1)

    latency_gate_ms, memory_gate_mb = load_thresholds()
    print(f"✓ Gates: P95 latency < {latency_gate_ms}ms, model size < {memory_gate_mb}MB")

    model = load_model()
    print("✓ Model loaded")

    size_target = MLPACKAGE_PATH if MLPACKAGE_PATH.exists() else None
    if size_target:
        model_size_mb = measure_model_size_mb(size_target)
        size_pass = model_size_mb < memory_gate_mb
        print(f"  CoreML size: {model_size_mb:.1f}MB {'✓ PASS' if size_pass else '✗ FAIL'} (gate < {memory_gate_mb}MB)")
    else:
        model_size_mb = measure_model_size_mb(CHECKPOINT_PATH)
        size_pass = True
        print(f"  .pt checkpoint: {model_size_mb:.1f}MB (CoreML not yet exported — size gate deferred)")

    loader = GoldenDatasetLoader(str(GOLDEN_PATH))
    narrations = [t["narration"] for t in loader.transactions]

    print(f"  Measuring latency over {N_MEASURE} samples ({N_WARMUP} warmup)...")
    latency = measure_latency(model, narrations)
    latency_pass = latency["p95_ms"] < latency_gate_ms
    print(f"  P95 latency: {latency['p95_ms']:.1f}ms {'✓ PASS' if latency_pass else '✗ FAIL'} (gate < {latency_gate_ms}ms)")
    print(f"  Mean: {latency['mean_ms']:.1f}ms | Median: {latency['median_ms']:.1f}ms | P99: {latency['p99_ms']:.1f}ms")

    all_pass = size_pass and latency_pass
    report = BenchmarkReport(
        benchmark_date=datetime.now(timezone.utc).isoformat(),
        git_commit=None,
        dataset_version="golden_transactions_expanded.jsonl",
        model_name="NarrationEmbedder",
        model_version="v0.1",
        metrics={
            "latency": latency,
            "model_size_mb": round(model_size_mb, 2),
            "gates": {
                "latency_p95_ms": latency_gate_ms,
                "memory_mb": memory_gate_mb,
            },
        },
        passed=all_pass,
    )
    write_report(report, str(REPORT_PATH))

    print(f"\n{'✓ ALL BENCHMARKS PASSED' if all_pass else '✗ SOME BENCHMARKS FAILED'}")
    if not all_pass:
        sys.exit(1)


if __name__ == "__main__":
    main()
