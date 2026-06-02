---
doc: 008-benchmark-plan
version: 0.1.0
status: Draft
date: 2026-06-02
---

# Benchmark Plan — FinanceIntelligence Platform

## Purpose

Define the complete benchmark strategy for all 11 ML models: what to measure, how to measure it, what the golden dataset looks like, how benchmarks run in CI, and what the acceptance thresholds are. A model that does not pass its benchmark cannot be promoted to `status: active`.

---

## Benchmark Goals

1. **Correctness:** Verify each model meets its F1 / accuracy / AUC targets on held-out data.
2. **Regression detection:** Catch accuracy regressions before they reach production.
3. **Latency:** Verify P95 inference latency meets the pipeline budget.
4. **Memory:** Verify peak RSS does not exceed per-model budget.
5. **Reproducibility:** Benchmarks produce the same result given the same model and dataset.

---

## Golden Dataset

**Location:** `training/data/golden_transactions.jsonl`

**Format (one JSON object per line):**
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

**Size targets:**
- Phase 1 (minimum viable): 500 labeled transactions
- Phase 2 (model training): 5,000 labeled transactions
- Phase 3 (full benchmark): 20,000 labeled transactions
- Long-term: 100,000+ (majority synthetic, all human-validated for golden set)

**Stratification requirements:**
- Each category class: minimum 30 examples
- Each intent class: minimum 30 examples
- Each bank format: minimum 20 examples
- UPI transactions: minimum 30% of dataset
- Income transactions: minimum 10% of dataset
- Unknown / edge case transactions: minimum 5% of dataset

---

## Per-Model Benchmark Scripts

### Model 1 — Merchant Recognition

**Script:** `training/merchant/benchmark.py`

```python
# Metrics computed:
# - Top-1 accuracy (predicted[0] == label)
# - Top-3 accuracy (label in predicted[:3])
# - Unknown merchant recall (narrations with no known merchant → "unknown")
# - Per-merchant precision and recall (for top-50 merchants by frequency)

python benchmark.py \
    --model-path artifacts/MerchantRecognizer_v1.0.mlpackage \
    --dataset training/data/golden_transactions.jsonl \
    --output reports/merchant_benchmark_v1.0.json
```

**Acceptance thresholds:**
- Top-1 Accuracy ≥ 0.95
- Top-3 Accuracy ≥ 0.99
- Unknown Merchant Recall ≥ 0.90

---

### Model 2 — Category Classifier

**Script:** `training/category/benchmark.py`

```python
# Metrics computed:
# - Macro F1 (unweighted mean across all classes)
# - Weighted F1 (weighted by class frequency)
# - Per-class precision, recall, F1
# - Confusion matrix
# - Coverage at confidence > 0.65 (% of predictions above threshold)
```

**Acceptance thresholds:**
- Macro F1 ≥ 0.92
- Weighted F1 ≥ 0.94
- No single class recall < 0.70
- Coverage at threshold ≥ 0.85

---

### Model 3 — Intent Classifier

**Script:** `training/intent/benchmark.py`

**Acceptance thresholds:**
- Macro F1 ≥ 0.95
- Weighted F1 ≥ 0.96
- salary recall ≥ 0.98 (critical class)
- credit_card_payment recall ≥ 0.95 (critical class)

---

### Model 4 — Recurring Detector

**Script:** `training/recurring/benchmark.py`

```python
# Metrics computed:
# - Precision, Recall, F1 per cadence class
# - Binary recurring / non-recurring Precision and Recall
# - Next-date prediction accuracy (within ±3 days)
```

**Acceptance thresholds:**
- Binary Precision ≥ 0.90
- Binary Recall ≥ 0.88
- Monthly cadence F1 ≥ 0.90

---

### Model 5 — Subscription Detector

**Script:** `training/subscription/benchmark.py`

**Acceptance thresholds:**
- Precision ≥ 0.93 (low false positive requirement)
- Recall ≥ 0.85

---

### Model 6 — Income Classifier

**Script:** `training/income/benchmark.py`

**Acceptance thresholds:**
- Binary income/non-income Precision ≥ 0.93
- Salary recall ≥ 0.97 (critical class)
- Macro F1 across income types ≥ 0.88

---

### Model 7 — Embedding Model

**Script:** `training/embedding/benchmark.py`

```python
# Metrics computed:
# - Triplet loss on held-out (anchor, positive, negative) triplets
# - Same-merchant cosine similarity mean (should be > 0.85)
# - Different-merchant cosine similarity mean (should be < 0.30)
# - Merchant clustering purity (k-means with k = # true merchants)
# - ANN retrieval accuracy: top-1 recall at k=1, k=5, k=10
```

**Acceptance thresholds:**
- Same-merchant mean cosine similarity ≥ 0.85
- Different-merchant mean cosine similarity ≤ 0.30
- ANN Top-1 Recall ≥ 0.90

---

### Model 8 — Link Prediction

**Script:** `training/link_prediction/benchmark.py`

```python
# Metrics computed:
# - AUC-ROC on held-out positive and negative graph edges
# - Hits@1, Hits@3, Hits@10
# - Mean Reciprocal Rank (MRR)
```

**Acceptance thresholds:**
- AUC-ROC ≥ 0.85
- Hits@1 ≥ 0.65
- MRR ≥ 0.70

---

### Model 9 — Anomaly Detector

**Script:** `training/anomaly/benchmark.py`

```python
# Metrics computed:
# - Precision, Recall, F1 on labeled anomalous transactions
# - False Positive Rate (FPR) on normal transaction set
# - Per-anomaly-type Precision and Recall
```

**Acceptance thresholds:**
- Precision ≥ 0.80
- FPR ≤ 0.05 (critical — user trust depends on low false positives)
- Recall ≥ 0.75

---

### Model 10 — Description Generator

**Script:** `training/description/benchmark.py`

```python
# Metrics computed:
# - BERTScore (semantic similarity to human reference)
# - ROUGE-1, ROUGE-L against reference descriptions
# - Factuality score: do numeric values (amount, date) in output match input?
# - Human evaluation panel: 50 sample descriptions rated 1–5
```

**Acceptance thresholds:**
- BERTScore F1 ≥ 0.85
- Factuality ≥ 0.99 (wrong amounts are critical failures)
- Human eval mean ≥ 3.5/5

---

### Model 11 — Insight Generator

**Script:** `training/insight/benchmark.py`

```python
# Metrics computed:
# - Factuality: all statistics cited in output match input context
# - Coherence: semantic similarity to reference insights (BERTScore)
# - Coverage: fraction of key insight topics mentioned
# - Hallucination rate: outputs mentioning facts not in input context
```

**Acceptance thresholds:**
- Factuality ≥ 0.99
- Hallucination rate ≤ 0.02
- Human eval coherence mean ≥ 4.0/5

---

## Latency Benchmark

**Script:** `training/scripts/latency_benchmark.py`

Runs inference on 1,000 transactions and records per-stage latency.

```python
python latency_benchmark.py \
    --device cpu \        # also run with --device ane (Apple Neural Engine)
    --n-transactions 1000 \
    --warmup 50 \
    --output reports/latency_$(date +%Y%m%d).json
```

**Reported metrics:**
- Mean, P50, P90, P95, P99 latency per stage
- Total pipeline P95 latency
- Cold start time (first inference after model load)
- Warm start time (subsequent inferences)

**Acceptance thresholds:**
- Total pipeline P95 < 200 ms
- No single stage P95 > 50 ms (except MLX stages)
- Cold start < 2 s per model

---

## Memory Benchmark

**Script:** `training/scripts/memory_benchmark.py`

```python
# Measures peak RSS with all models loaded simultaneously
# Tests: load sequence, inference sequence, unload sequence

# Acceptance:
# - All CoreML models loaded: peak RSS increase < 150 MB
# - Per-model peak RSS increase < 50 MB
# - MLX LLM (description/insight): < 2 GB (gated on device capability)
```

---

## CI Integration

Benchmark runs are triggered on:
1. New model artifact added to `training/artifacts/`
2. PR touches `Sources/FinanceIntelligence/` (latency benchmark only)
3. Weekly scheduled run (full accuracy benchmark)

**CI script:** `.github/workflows/benchmark.yml`

```yaml
- name: Run model benchmarks
  run: |
    cd training
    python scripts/run_all_benchmarks.py \
      --dataset data/golden_transactions.jsonl \
      --output reports/ci_$(git rev-parse --short HEAD).json
      
- name: Check thresholds
  run: |
    python scripts/check_thresholds.py \
      --report reports/ci_$(git rev-parse --short HEAD).json \
      --thresholds config/benchmark_thresholds.yaml
```

Threshold check fails the CI build if any model drops below its acceptance threshold.

---

## Benchmark Report Format

```json
{
  "benchmark_date": "2026-06-02T10:00:00Z",
  "git_commit": "abc1234",
  "dataset_version": "2026-05-15",
  "models": {
    "category_classifier": {
      "version": "1.2.0",
      "macro_f1": 0.937,
      "weighted_f1": 0.951,
      "accuracy": 0.949,
      "per_class": { "food": {"precision": 0.96, "recall": 0.94, "f1": 0.95}, ... },
      "latency_p95_ms": 18.3,
      "peak_rss_mb": 22.1,
      "passed": true
    }
  }
}
```

---

## Risks

| Risk | Mitigation |
|---|---|
| Golden dataset too small for statistical significance | Require minimum 30 examples per class; report confidence intervals on F1 |
| Benchmark environment latency differs from device | Always report device spec alongside benchmark; target iPhone 12 as minimum device |
| Human evaluation subjectivity for Models 10/11 | Use standardized rubric with 3 independent annotators; report inter-annotator agreement |
| Benchmark overfitting (model trained on golden set) | Strict train/test split; golden test set never used in training |
