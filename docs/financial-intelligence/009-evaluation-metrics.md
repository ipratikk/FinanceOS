---
doc: 009-evaluation-metrics
version: 0.1.0
status: Draft
date: 2026-06-02
---

# Evaluation Metrics — FinanceIntelligence Platform

## Purpose

Define the complete evaluation methodology for the FinanceIntelligence platform. This document specifies which metrics apply to each model, how each metric is computed, what the acceptance thresholds are, and how results are interpreted.

---

## Metric Taxonomy

| Metric Family | Applicable Models |
|---|---|
| Classification (F1, Precision, Recall) | Models 1, 2, 3, 5, 6 |
| Binary classification (AUC-ROC) | Models 5, 8, 9 |
| Ranking (Top-K Accuracy, MRR, Hits@K) | Models 1, 7, 8 |
| Regression / Structured (date accuracy) | Model 4 |
| Embedding quality (cosine sim, triplet) | Model 7 |
| Generative quality (BERTScore, ROUGE) | Models 10, 11 |
| Factuality (grounding check) | Models 10, 11 |
| Latency (P50, P95, P99) | All |
| Memory (peak RSS) | All |

---

## Classification Metrics

### Macro F1

Used for all multi-class models to measure equal-weight performance across classes regardless of class imbalance.

```
F1_class_i = 2 * precision_i * recall_i / (precision_i + recall_i)
Macro_F1   = (1/N) * Σ F1_class_i
```

Macro F1 is the primary metric for Models 2, 3, and 6. It penalizes poor performance on minority classes (e.g., `donations`, `taxes`) equally with majority classes.

### Weighted F1

Used as a secondary metric, reflecting real-world distribution impact.

```
Weighted_F1 = Σ (support_i / total_support) * F1_class_i
```

### Per-Class Metrics

Every evaluation report must include per-class precision, recall, and F1 for every output class. Aggregate metrics can hide critical class failures (e.g., salary misclassification is catastrophic even if overall F1 is high).

### Confusion Matrix

Required for all classification models. Exported as part of benchmark report. Key failure modes to inspect:
- Category confusion: food vs. groceries vs. dining
- Intent confusion: salary vs. peer_transfer
- Income/expense direction errors

---

## Ranking Metrics

### Top-K Accuracy (Models 1, 7)

```
Top-K Accuracy = fraction of examples where true label is in top-K predictions
```

For Merchant Recognition (Model 1):
- Top-1 ≥ 0.95 (primary)
- Top-3 ≥ 0.99 (secondary)

### Mean Reciprocal Rank (Model 8)

```
MRR = (1/|Q|) * Σ (1 / rank_i)
```
where `rank_i` is the rank of the correct answer in the prediction list.

### Hits@K (Model 8)

```
Hits@K = fraction of queries where correct answer appears in top-K results
```

---

## Binary Classification Metrics

### AUC-ROC (Models 5, 8, 9)

Area under the Receiver Operating Characteristic curve. Threshold-independent measure of discriminative ability.

```
AUC = P(score(positive) > score(negative))
```

For Anomaly Detection (Model 9): AUC ≥ 0.85, but FPR at operating threshold ≤ 0.05 is the binding constraint (user-facing false alarms are expensive).

### Precision-Recall AUC

Preferred over ROC-AUC for highly imbalanced datasets (e.g., anomaly detection where anomalies are rare). Both metrics reported.

---

## Embedding Quality Metrics

### Cosine Similarity Distribution

```python
# Same-merchant pairs (positive pairs)
# Expected: cosine_sim(embed_a, embed_b) > 0.85

# Different-category pairs (hard negatives)
# Expected: cosine_sim(embed_a, embed_b) < 0.30
```

### Triplet Accuracy

```
triplet_accuracy = fraction of (anchor, positive, negative) where:
    cos(anchor, positive) > cos(anchor, negative)
```

Target: triplet_accuracy ≥ 0.90 on held-out triplets.

### Merchant Clustering Purity

Run k-means clustering on embeddings with k = number of known merchants. Purity = fraction of cluster members that share the majority label.

Target: clustering purity ≥ 0.85.

---

## Generative Quality Metrics

### BERTScore

Semantic similarity between generated text and human reference using contextual embeddings.

```
BERTScore_F1 = F1 between token-level similarity of output and reference
```

Computed using `bert-score` Python library with `distilbert-base-multilingual-cased` (handles Hindi merchant names in descriptions).

Target: BERTScore F1 ≥ 0.85 for description generation.

### ROUGE-1, ROUGE-L

N-gram overlap metrics for surface-level similarity.

```
ROUGE-1 = unigram overlap (recall-oriented)
ROUGE-L = longest common subsequence
```

Used as secondary metrics alongside BERTScore.

### Factuality Score

Critical for financial descriptions and insights. Measures whether numeric values (amounts, dates, category names) cited in generated output match the input context.

```python
def factuality_score(output: str, input_context: dict) -> float:
    """
    Extract all numeric values and named entities from output.
    Check each against input_context.
    Return fraction that are grounded.
    """
```

Target: Factuality ≥ 0.99. A description that states the wrong amount is a critical failure.

### Hallucination Rate

```
hallucination_rate = fraction of outputs containing at least one ungrounded fact
```

Target: ≤ 0.02 (no more than 2% of generated descriptions/insights contain hallucinated facts).

---

## Latency Metrics

### Measurement Protocol

```python
# Warm-up: 50 inferences discarded
# Measurement: 1,000 inferences
# Device: record device model + chip in report
# Thermal state: must be "nominal" (not throttled)

latencies = []
for txn in test_transactions:
    start = time.perf_counter()
    result = model.predict(txn)
    end = time.perf_counter()
    latencies.append((end - start) * 1000)  # ms

report = {
    "mean": statistics.mean(latencies),
    "p50": statistics.median(latencies),
    "p90": percentile(latencies, 90),
    "p95": percentile(latencies, 95),
    "p99": percentile(latencies, 99),
    "cold_start": cold_start_ms,
}
```

### Latency Acceptance Thresholds

| Model | P95 Target | Cold Start Target |
|---|---|---|
| MerchantRecognizer | < 20 ms | < 1,000 ms |
| CategoryClassifier | < 20 ms | < 1,000 ms |
| IntentClassifier | < 15 ms | < 800 ms |
| IncomeClassifier | < 15 ms | < 800 ms |
| EmbeddingGenerator | < 30 ms | < 1,500 ms |
| RecurringDetector | < 20 ms | < 800 ms |
| AnomalyDetector | < 20 ms | < 800 ms |
| Total pipeline (sync) | < 200 ms | < 3,000 ms |
| DescriptionGenerator (MLX) | < 2,000 ms | < 5,000 ms |
| InsightGenerator (MLX) | < 5,000 ms | < 8,000 ms |

---

## Memory Metrics

### Measurement Protocol

```python
import tracemalloc
import resource

tracemalloc.start()
# Load all CoreML models
# Run 100 inferences
peak_memory = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
```

### Memory Acceptance Thresholds

| Scope | Budget |
|---|---|
| Single CoreML model (load + inference) | < 50 MB peak RSS increase |
| All CoreML models loaded simultaneously | < 150 MB peak RSS increase |
| MLX LLM (Phi-3 mini / Qwen3 4B) | < 2,000 MB (4-bit quantized) |
| Embedding ANN index (10K transactions) | < 20 MB |

---

## Statistical Significance

For A/B comparisons between model versions:

- Report McNemar's test p-value when comparing two classifiers on paired data
- Require p < 0.05 for promotion claim of "statistically significantly better"
- Report 95% confidence intervals on F1 using bootstrap resampling (1,000 samples)

---

## Calibration Metrics

Confidence scores from models should be calibrated (confidence 0.9 should be right ~90% of the time).

**Expected Calibration Error (ECE):**
```
ECE = Σ_b (|B_b| / n) * |accuracy(B_b) - confidence(B_b)|
```
where B_b are equal-width confidence bins.

Target: ECE < 0.05 for all classification models.

If ECE > 0.10, apply temperature scaling post-training.

---

## Per-Release Evaluation Checklist

Before every model promotion to `status: active`:

- [ ] Full golden dataset benchmark run completed
- [ ] All acceptance thresholds met
- [ ] Per-class metrics reviewed for critical classes
- [ ] Confusion matrix reviewed for failure patterns
- [ ] Latency P95 within budget
- [ ] Peak memory within budget
- [ ] ECE < 0.05 (or temperature scaling applied)
- [ ] Benchmark report committed to `reports/` directory
- [ ] `model_registry.yaml` updated with metrics
- [ ] PR reviewed by at least one engineer

---

## Evaluation Report Schema

```json
{
  "model_name": "category_classifier",
  "model_version": "1.2.0",
  "evaluation_date": "2026-06-02",
  "dataset_version": "2026-05-15",
  "dataset_size": 2500,
  "device": "Apple M2, macOS 15.2",
  "metrics": {
    "macro_f1": 0.937,
    "weighted_f1": 0.951,
    "accuracy": 0.949,
    "ece": 0.038,
    "per_class": {
      "groceries": {"precision": 0.96, "recall": 0.94, "f1": 0.95, "support": 180},
      "dining": {"precision": 0.93, "recall": 0.91, "f1": 0.92, "support": 120},
      "salary": {"precision": 0.99, "recall": 0.98, "f1": 0.985, "support": 85}
    },
    "latency_p95_ms": 18.3,
    "cold_start_ms": 892,
    "peak_rss_mb": 22.1
  },
  "thresholds_passed": true,
  "failures": []
}
```
