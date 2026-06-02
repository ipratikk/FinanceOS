# FinanceOS Financial Intelligence Training Pipeline

ML training infrastructure for the Financial Intelligence Platform (11 models).

## Directory Structure

```
training/
├── data/                    # Dataset generation and export
│   ├── export.py           # GRDB → training CSV export
│   └── golden_transactions.jsonl  # 500-5000 hand-labeled golden set
├── scripts/                # Shared utilities
│   ├── run_all_benchmarks.py      # Run all 11 model benchmarks
│   └── compute_artifact_hash.py   # SHA256 for model_registry.yaml
├── config/
│   └── benchmark_thresholds.yaml  # Per-model acceptance thresholds
├── {category,merchant,intent,income,recurring}/
│   ├── train.py            # Model training script
│   ├── export_coreml.py    # CoreML export via coremltools
│   ├── benchmark.py        # Per-model evaluation harness
│   └── __init__.py
├── embedding/              # Sentence transformer (Phase 4)
├── anomaly/                # Anomaly detector (Phase 6)
├── link_prediction/        # Link predictor GNN (Phase 6)
└── retraining/             # Incremental retraining (Phase 7)
```

## Setup

```bash
pip install -r requirements.txt
```

## Phase 1: Foundation

### 1. Generate Golden Dataset
```bash
python data/export.py --source-db /path/to/financeos.sqlite \
  --output data/golden_transactions.jsonl \
  --count 500
```

### 2. Run Benchmarks
```bash
python scripts/run_all_benchmarks.py \
  --dataset data/golden_transactions.jsonl \
  --output reports/phase1_baseline.json
```

### 3. Compute Model Hashes
```bash
python scripts/compute_artifact_hash.py \
  artifacts/TransactionCategoryClassifier_v1.1.mlpackage
```

## Phase 2+: Model Training

Each model directory contains:
- `train.py` — training script with argparse
- `export_coreml.py` — CoreML export
- `benchmark.py` — evaluation on golden set

Example:
```bash
cd category
python train.py --dataset ../data/category_training.csv \
  --epochs 20 \
  --output-model artifacts/CategoryClassifier_v1.2.mlpackage

python benchmark.py \
  --model artifacts/CategoryClassifier_v1.2.mlpackage \
  --dataset ../data/golden_transactions.jsonl
```

## Benchmark Report Format

JSON reports include:
- Model version and training date
- Per-class metrics (precision, recall, F1)
- Confusion matrix
- Overall macro/weighted F1
- Latency percentiles (P50, P95, P99)
- Memory usage (peak RSS)
- Pass/fail against thresholds

## Golden Dataset Schema

```json
{
  "transaction_id": "txn_001",
  "narration": "UPI-ZEPTO MARKETPLACE PR-9876543210@ybl-ZPT0001",
  "amount": 349.00,
  "direction": "debit",
  "payment_channel": "upi",
  "upi_vpa": "9876543210@ybl",
  "date": "2026-05-15",
  "bank": "HDFC",
  "labels": {
    "merchant": "Zepto",
    "category": "groceries",
    "subcategory": null,
    "intent": "grocery",
    "is_income": false,
    "income_type": null,
    "is_recurring": false,
    "recurring_cadence": null,
    "is_subscription": false
  },
  "annotator": "human",
  "annotation_date": "2026-05-01",
  "confidence": "high"
}
```

## CI Integration

Benchmarks run automatically:
- On new model artifacts in `/training/artifacts/`
- Weekly scheduled full suite
- PR changes to `Sources/FinanceIntelligence/`

See `.github/workflows/benchmark.yml` (Phase 7).
