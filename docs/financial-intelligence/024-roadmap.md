---
doc: 024-roadmap
version: 0.1.0
status: Draft
date: 2026-06-02
---

# Platform Roadmap — FinanceIntelligence

## Purpose

Define the phased implementation roadmap for the complete FinanceIntelligence platform. This document specifies what gets built in each phase, the dependencies between phases, sprint estimates, acceptance criteria per phase, and migration steps from the existing implementation.

---

## Guiding Principle

**Dataset first. Evaluation second. Model third. Integration last.**

No model ships without: (1) a labeled dataset, (2) a benchmark showing it beats the baseline, and (3) a fallback for when it fails.

---

## Phase Overview

| Phase | Name | Duration | Outcome |
|---|---|---|---|
| Phase 1 | Foundation | 2 sprints | Evaluation harness + dataset pipeline |
| Phase 2 | Category + Merchant ML | 2 sprints | Models 1 + 2 deployed, baselines retired |
| Phase 3 | Behavioral Intelligence | 2 sprints | Models 3, 4, 5, 6 deployed |
| Phase 4 | Embeddings + Graph | 2 sprints | Model 7 deployed; personalization upgraded |
| Phase 5 | Generative + Agent | 3 sprints | Models 10, 11 + FinanceAgent |
| Phase 6 | Link + Anomaly | 2 sprints | Models 8, 9 deployed |
| Phase 7 | Hardening | 2 sprints | Full benchmark suite, CI, feedback loops |

Total: ~15 sprints (30 weeks at 2-week sprints)

---

## Phase 1 — Foundation

**Duration:** 2 sprints (4 weeks)

### Goals

1. Create complete documentation (`docs/financial-intelligence/` — this doc set)
2. Build evaluation harness (`Evaluation/EvaluationHarness.swift`, `training/scripts/`)
3. Build golden transaction dataset (500 labeled transactions minimum)
4. Build training data export pipeline (`training/data/export.py`)
5. Establish ModelRegistry infrastructure (`LocalModelRegistry.swift`, `model_registry.yaml`)
6. Wire `CoreMLCategorizer` to `ModelRegistry` (remove hardcoded filename)
7. Run baseline evaluation on existing `CoreMLCategorizer` and `RuleBasedCategorizer`

### Deliverables

- [ ] `docs/financial-intelligence/` — all 25 documents (this doc set)
- [ ] `training/data/golden_transactions.jsonl` — 500 hand-labeled transactions
- [ ] `training/category/benchmark.py` — baseline evaluation run
- [ ] `Sources/FinanceIntelligence/Infrastructure/LocalModelRegistry.swift`
- [ ] `Sources/FinanceIntelligence/Resources/model_registry.yaml`
- [ ] Baseline report: `reports/baseline_2026_06.json`

### Acceptance Criteria

- Evaluation harness runs on CI and produces a benchmark report
- Baseline F1 for `CoreMLCategorizer` measured and documented
- `LocalModelRegistry` loads existing model correctly
- No regressions in existing functionality

---

## Phase 2 — Category + Merchant ML

**Duration:** 2 sprints (4 weeks)

### Goals

1. Generate `category_training.csv` (synthetic + exported) — 50,000 examples
2. Train `CategoryClassifier` v1.2 with subcategory support
3. Export via `training/category/export_coreml.py`
4. Generate `merchant_training.csv` — 100,000 examples with UPI VPA variations
5. Train `MerchantRecognizer` v0.9
6. Export via `training/merchant/export_coreml.py`
7. A/B test both models vs. existing baselines
8. Deploy to `model_registry.yaml` as `status: shadow` → `status: active`
9. Deprecate `RuleBasedCategorizer` from primary path
10. Deprecate `MerchantAliasTable` from primary path

### Deliverables

- [ ] `training/category/train.py` + `export_coreml.py` + `benchmark.py`
- [ ] `training/merchant/train.py` + `export_coreml.py` + `benchmark.py`
- [ ] `datasets/category_training.csv`
- [ ] `datasets/merchant_training.csv`
- [ ] `Sources/FinanceIntelligence/Categorization/CoreMLCategoryClassifier.swift`
- [ ] `Sources/FinanceIntelligence/MerchantRecognition/CoreMLMerchantRecognizer.swift`
- [ ] Benchmark reports: `reports/category_v1.2_benchmark.json`, `reports/merchant_v0.9_benchmark.json`

### Acceptance Criteria

- Category Macro F1 ≥ 0.92 on golden test set
- Merchant Top-1 Accuracy ≥ 0.95 on golden test set
- A/B test: new models correct rate ≥ existing baseline correct rate
- `RuleBasedCategorizer` remains as fallback; not primary path
- `MerchantAliasTable` remains as fallback; not primary path

---

## Phase 3 — Behavioral Intelligence

**Duration:** 2 sprints (4 weeks)

### Goals

1. Generate `intent_training.csv` — 50,000 examples
2. Train `IntentClassifier` v0.1
3. Generate `income_training.csv` — 20,000 examples  
4. Train `IncomeClassifier` v0.1
5. Generate `recurring_training.csv` — 20,000 sequence examples
6. Train `RecurringDetector` v0.1 (tabular)
7. Build `SubscriptionDetector` (hybrid: Model 4 + subscription merchant list)
8. Integrate all 4 models into `IntelligencePipeline`

### Deliverables

- [ ] `training/intent/` — full training pipeline
- [ ] `training/income/` — full training pipeline
- [ ] `training/recurring/` — full training pipeline
- [ ] `Sources/FinanceIntelligence/IntentDetection/CoreMLIntentClassifier.swift`
- [ ] `Sources/FinanceIntelligence/IncomeDetection/CoreMLIncomeClassifier.swift`
- [ ] `Sources/FinanceIntelligence/RecurringDetection/CoreMLRecurringDetector.swift`
- [ ] `Sources/FinanceIntelligence/SubscriptionDetection/HybridSubscriptionDetector.swift`
- [ ] Integration tests: `PipelineIntegrationTests.swift`

### Acceptance Criteria

- Intent Macro F1 ≥ 0.95
- Income binary precision ≥ 0.93
- Recurring binary precision ≥ 0.90
- Subscription precision ≥ 0.93
- Full pipeline P95 latency < 200 ms (all 7 models loaded)

---

## Phase 4 — Embeddings + Personalization

**Duration:** 2 sprints (4 weeks)

### Goals

1. Train `EmbeddingModel` v0.1 (sentence transformer, fine-tuned on Indian financial narrations)
2. Export as CoreML (Float32[128] output)
3. Build `EmbeddingStore` (GRDB persistence for embeddings)
4. Build `ANNIndex` (approximate nearest neighbor for personalization)
5. Upgrade `PersonalizedClassifier` to use Model 7 embeddings (replace TF-IDF)
6. Build `UserKnowledgeGraph` personalization layer

### Deliverables

- [ ] `training/embedding/` — full training pipeline with triplet contrastive data
- [ ] `Sources/FinanceIntelligence/Embeddings/CoreMLEmbeddingGenerator.swift`
- [ ] `Sources/FinanceIntelligence/Embeddings/EmbeddingStore.swift`
- [ ] `Sources/FinanceIntelligence/Embeddings/ANNIndex.swift`
- [ ] `Sources/FinanceIntelligence/Personalization/PersonalizedClassifier.swift` — upgraded
- [ ] `Sources/FinanceIntelligence/Personalization/UserKnowledgeGraph.swift`

### Acceptance Criteria

- Same-merchant mean cosine similarity ≥ 0.85
- ANN Top-1 recall ≥ 0.90
- PersonalizedClassifier correction rate improvement measurable after 20 user corrections
- Embedding generation P95 latency < 30 ms

---

## Phase 5 — Generative + Agent

**Duration:** 3 sprints (6 weeks)

### Goals

1. MLX Swift integration (`LocalLLM/` module)
2. Model evaluation: Phi-3 Mini vs. Qwen3 4B on description + insight tasks
3. Build `MLXDescriptionGenerator` with factuality guard
4. Build `MLXInsightGenerator` with `SpendingInsightEngine` statistics grounding
5. Build `FinanceAgent` with 7 tools
6. Fine-tune description model with `transaction_description_training.jsonl`
7. Build description generation batching queue

### Deliverables

- [ ] `Sources/FinanceIntelligence/LocalLLM/` — complete MLX integration
- [ ] `Sources/FinanceIntelligence/DescriptionGeneration/MLXDescriptionGenerator.swift`
- [ ] `Sources/FinanceIntelligence/InsightGeneration/MLXInsightGenerator.swift`
- [ ] `Sources/FinanceIntelligence/Agent/FinanceAgent.swift`
- [ ] `Sources/FinanceIntelligence/Agent/Tools/` — all 7 tools
- [ ] `training/description/` — fine-tuning pipeline
- [ ] `training/insight/` — evaluation pipeline
- [ ] `docs/financial-intelligence/020-local-llm-evaluation.md` — updated with real benchmark results

### Acceptance Criteria

- Description BERTScore F1 ≥ 0.85
- Description factuality ≥ 0.99
- Agent answers basic financial questions correctly (manual eval on 20 sample queries)
- MLX LLM loads in < 5 s on iPhone 15 Pro
- No crash on devices without Apple Intelligence or < 6 GB RAM

---

## Phase 6 — Link + Anomaly

**Duration:** 2 sprints (4 weeks)

### Goals

1. Train `AnomalyDetector` v0.1 (Isolation Forest / One-Class SVM)
2. Build `StatisticalAnomalyDetector` (z-score baseline)
3. Build `UserHistoryBuilder` (materialized per-session stats)
4. Train `LinkPredictor` v0.1 (TransE on knowledge graph)
5. Build `MLXLinkPredictor` Swift implementation
6. Integrate anomaly detection into pipeline (Stage 8)
7. Integrate link prediction as async post-processing

### Deliverables

- [ ] `training/anomaly/` — training + export pipeline
- [ ] `training/link_prediction/` — TransE training pipeline
- [ ] `Sources/FinanceIntelligence/AnomalyDetection/CoreMLAnomalyDetector.swift`
- [ ] `Sources/FinanceIntelligence/AnomalyDetection/StatisticalAnomalyDetector.swift`
- [ ] `Sources/FinanceIntelligence/AnomalyDetection/UserHistoryBuilder.swift`
- [ ] `Sources/FinanceIntelligence/LinkPrediction/MLXLinkPredictor.swift`

### Acceptance Criteria

- Anomaly FPR ≤ 0.05
- Anomaly precision ≥ 0.80
- Duplicate detection precision ≥ 0.95
- Link prediction AUC-ROC ≥ 0.85

---

## Phase 7 — Hardening

**Duration:** 2 sprints (4 weeks)

### Goals

1. Full CI benchmark pipeline for all 11 models
2. Feedback export pipeline (`FeedbackExporter`)
3. Incremental retraining pipeline (`training/retraining/`)
4. `model_registry.yaml` promotion/rollback workflow documented and tested
5. Golden dataset expanded to 5,000 transactions
6. Performance regression tests in CI
7. Documentation finalized (all 25 docs reviewed and updated)

### Deliverables

- [ ] `.github/workflows/benchmark.yml` — CI benchmark pipeline
- [ ] `training/retraining/` — merge_feedback, build_incremental_dataset, train_incremental, evaluate_incremental, promote_model
- [ ] `training/data/golden_transactions.jsonl` — 5,000 examples
- [ ] `Sources/FinanceIntelligence/Personalization/FeedbackExporter.swift`
- [ ] Full test coverage in `FinanceIntelligenceTests/`

### Acceptance Criteria

- All 11 models pass their benchmark thresholds
- CI build fails if any model regresses > 0.01 F1
- Feedback → training data export works end-to-end
- Incremental retraining pipeline produces valid model artifacts

---

## Migration Plan from Existing Implementation

### Deprecation Schedule

| Component | Deprecated In | Removed In |
|---|---|---|
| `RuleBasedCategorizer` (primary path) | Phase 2 | Phase 3 |
| `MerchantAliasTable` (primary path) | Phase 2 | Phase 3 |
| Hardcoded model filename in `CoreMLCategorizer` | Phase 1 | Phase 1 |
| `RuleBasedCategorizer` (fallback) | Phase 3 | Phase 4 |
| `MerchantAliasTable` (fallback) | Phase 3 | Phase 4 |
| TF-IDF in `PersonalizedClassifier` | Phase 4 | Phase 5 |
| `FallbackGenerator` (primary path) | Phase 5 | Never (kept as emergency fallback) |
| Magic number `confidenceThreshold = 0.65` | Phase 1 | Phase 1 (moved to registry metadata) |
| Magic number cadence windows in `PatternAnalyzer` | Phase 3 | Phase 4 |

### Rollback Safety

Each migration step must:
1. Keep the old component as a fallback (not deleted)
2. A/B test the new component for 1 sprint before promotion
3. Have a one-line configuration switch to revert to old behavior
4. Never break existing tests

---

## Success Criteria (Platform Complete)

The platform is considered complete when ALL of the following are true:

- [ ] 11 ML models deployed and registered in `model_registry.yaml`
- [ ] All models pass their benchmark thresholds
- [ ] Training pipeline reproducible from source on a clean environment
- [ ] Dataset generation scripts produce labeled datasets
- [ ] Evaluation harness runs in CI
- [ ] CoreML export pipeline produces deterministic artifacts
- [ ] MLX integration operational on iPhone 15 Pro + M2 Mac
- [ ] FinanceAgent answers 18/20 sample queries correctly (per manual eval)
- [ ] Feedback collection → training data export pipeline operational
- [ ] Incremental retraining pipeline tested end-to-end
- [ ] Zero `narration.contains()` in production inference code
- [ ] Zero hardcoded merchant dictionaries in production inference code
- [ ] Total pipeline P95 latency < 200 ms on iPhone 15 Pro
