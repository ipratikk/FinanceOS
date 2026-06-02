---
doc: 002-gap-analysis
version: 0.1.0
status: Draft
date: 2026-06-02
---

# Gap Analysis — Current State vs. Target ML Platform

## Purpose

This document identifies, for each of the 11 target ML models and each platform capability, the gap between the current implementation and the production target. Each gap entry includes: current coverage estimate, gap description, migration path, effort estimate, and risk level.

Effort scale: S (< 1 sprint), M (1–2 sprints), L (2–4 sprints), XL (> 4 sprints)
Risk scale: Low / Medium / High / Critical

---

## Model Gaps

### Model 1 — Merchant Recognition

| Attribute | Value |
|---|---|
| Current coverage | ~8% (40 merchants in MerchantAliasTable) |
| Target | Top-1 accuracy > 95% |
| Current component | `MerchantNormalizer` + `MerchantAliasTable` |

**Gap description:** The current alias table covers only ~40 merchants against a long tail of thousands of Indian merchants visible across UPI, card, and bank transfer transactions. Unknown merchants are returned as raw narration fragments. There is no ML-based recognition whatsoever.

**Migration path:**
1. Build labeled dataset: (narration, canonical_merchant_name) pairs by mining existing transaction data + MerchantAliasTable
2. Augment with synthetic UPI VPA variations per known merchant
3. Train NLModel text classifier via Python + coremltools
4. Integrate via `CoreMLMerchantRecognizer` (new class, mirrors `CoreMLCategorizer` pattern)
5. Wire to `ModelRegistry`
6. Deprecate `MerchantAliasTable` post-evaluation

**Effort:** L
**Risk:** High (dataset quality is the limiting factor; Indian merchant name variation is extremely high)

---

### Model 2 — Category Classifier

| Attribute | Value |
|---|---|
| Current coverage | ~65% (CoreMLCategorizer deployed; RuleBasedCategorizer as fallback) |
| Target | Macro F1 > 0.92 |
| Current component | `CoreMLCategorizer` (deployed), `RuleBasedCategorizer` (fallback) |

**Gap description:** The model is deployed but: (a) subcategory labels are not supported, (b) the model was trained on an undocumented dataset with no version pin, (c) there is no evaluation harness to measure the current F1, (d) the model artifact filename is hardcoded and not registered in `ModelRegistry`.

**Migration path:**
1. Build evaluation harness (benchmark.py) — this unblocks everything else
2. Run baseline evaluation on current model against held-out test set
3. Expand label set to include subcategory (e.g., Food > Restaurant, Food > Grocery)
4. Retrain with subcategory labels
5. Wire artifact to `ModelRegistry`
6. A/B test new model vs. current production model

**Effort:** M
**Risk:** Medium (model already exists; main work is evaluation infrastructure and subcategory dataset)

---

### Model 3 — Intent Classifier

| Attribute | Value |
|---|---|
| Current coverage | 0% |
| Target | Macro F1 > 0.95 |
| Current component | None |

**Gap description:** Intent classification (Purchase / Transfer / Bill Payment / Income / Refund / Withdrawal / Fee / Investment / Loan) does not exist. The `RuleEngine` has primitive salary and refund detection in `BuiltInRules`, but it does not expose an intent enum and has no evaluation metrics.

**Migration path:**
1. Define `TransactionIntent` enum in FinanceCore
2. Label training dataset with intent labels (partially derivable from existing category labels + narration patterns)
3. Train NLModel classifier
4. Export via coremltools
5. Create `CoreMLIntentClassifier` following `CoreMLCategorizer` pattern
6. Wire to inference pipeline (stage 6 in `005-inference-pipeline.md`)
7. Retire `BuiltInRules` salary/refund detection in favor of Model 3

**Effort:** M
**Risk:** Medium (intent often correlates with category; joint training possible)

---

### Model 4 — Recurring Detector

| Attribute | Value |
|---|---|
| Current coverage | ~40% (RecurringDetector with heuristics) |
| Target | Precision > 0.90, Recall > 0.88 at cadence level |
| Current component | `RecurringDetector`, `PatternAnalyzer` |

**Gap description:** The heuristic-based detector handles monthly and weekly cadences but misses irregular-but-recurring patterns (quarterly, biannual, irregular subscriptions). The amount tolerance (±5%) is too tight for utility bills and too loose for exact-amount subscriptions.

**Migration path:**
1. Export labeled recurring/non-recurring pairs from existing `RecurringDetector` output as training signal
2. Engineer features: amount_delta, day_of_month_variance, merchant_consistency, cadence_entropy
3. Train tabular regressor (scikit-learn → CoreML tabular model)
4. Build `CoreMLRecurringDetector` backed by Model 4
5. Retire magic number cadence windows from `PatternAnalyzer`

**Effort:** M
**Risk:** Medium (feature engineering dominates effort; model training is straightforward)

---

### Model 5 — Subscription Detector

| Attribute | Value |
|---|---|
| Current coverage | 0% (no dedicated subscription detection) |
| Target | Precision > 0.93 |
| Current component | Partially covered by `RecurringDetector` (no subscription-specific logic) |

**Gap description:** Subscription detection (distinguishing a recurring subscription from a recurring transfer or bill payment) does not exist as a standalone model. It requires merchant context (known subscription service list), amount consistency, and billing cycle alignment.

**Migration path:**
1. Build subscription merchant list (Netflix, Spotify, Adobe, Amazon Prime, etc. + Indian equivalents: ZEE5, Hotstar, JioSaavn, etc.)
2. Model as: recurring + subscription_merchant → subscription label
3. Rule+ML hybrid: rule-based subscription merchant matching + ML confidence calibration
4. Integrate as post-processing step after Model 4

**Effort:** S
**Risk:** Low (can leverage Model 4 output; merchant list is bounded)

---

### Model 6 — Income Classifier

| Attribute | Value |
|---|---|
| Current coverage | ~30% (SalaryAnalyzer for salary only) |
| Target | Precision > 0.93 for income classification |
| Current component | `SalaryAnalyzer` (salary only; no investment returns, rental income, etc.) |

**Gap description:** `SalaryAnalyzer` detects salary credits via NEFT/NACH + employer narration patterns. It does not detect: freelance payments, rental income, dividend credits, mutual fund redemptions, or peer-to-peer income. No confidence scoring exists.

**Migration path:**
1. Define `IncomeType` enum (Salary, Freelance, Rental, Dividend, Redemption, Refund, Gift, Other)
2. Label positive examples from `SalaryAnalyzer` output + manual annotation of credit transactions
3. Train NLModel classifier on income narrations
4. Create `CoreMLIncomeClassifier`
5. Integrate into inference pipeline as stage 8

**Effort:** M
**Risk:** Medium (labeling income vs. non-income credits requires careful annotation)

---

### Model 7 — Embedding Model

| Attribute | Value |
|---|---|
| Current coverage | 0% |
| Target | Cosine similarity meaningful for merchant clustering |
| Current component | None (PersonalizedClassifier uses TF-IDF, not embeddings) |

**Gap description:** No dense embedding representation exists for transactions. This blocks: (a) semantic similarity search in `PersonalizedClassifier`, (b) ANN-based nearest-neighbor lookup for personalization, (c) Link Prediction (Model 8) which requires entity embeddings.

**Migration path:**
1. Fine-tune a lightweight sentence transformer on Indian financial narration pairs (using contrastive learning: same merchant = similar, different category = dissimilar)
2. Export as CoreML model (Float32[128] output)
3. Build `NarrationEmbedder` Swift class
4. Store embeddings in GRDB (see `004-data-models.md`)
5. Replace TF-IDF in `PersonalizedClassifier` with embedding lookup
6. Build ANN index (Faiss or pure-Swift kd-tree for small corpora)

**Effort:** L
**Risk:** High (sentence transformer fine-tuning requires high-quality contrastive pairs; on-device model size constraint is tight)

---

### Model 8 — Link Prediction

| Attribute | Value |
|---|---|
| Current coverage | 0% |
| Target | Link prediction AUC > 0.85 |
| Current component | `RelationshipEngine` (manual relationship queries only) |

**Gap description:** The knowledge graph has edges but no ML-based link prediction. Suggested relationships (e.g., "this payment is likely to the same merchant as previous") require a GNN or embedding-dot-product model over graph structure.

**Migration path:**
1. Requires Model 7 (embeddings) as prerequisite
2. Build training pairs from KnowledgeGraph edges (positive = existing edge, negative = random non-edge)
3. Train TransE/DistMult-style embedding model in Python + MLX
4. Export MLX model weights
5. Implement `MLXLinkPredictor` Swift class
6. Integrate into `RelationshipEngine` as a suggestion layer

**Effort:** XL
**Risk:** High (GNN training requires sufficient graph density; MLX on-device inference is new infrastructure)

**Note:** Phase 4 deferred item. Requires Models 1 and 7 as prerequisites.

---

### Model 9 — Anomaly Detector

| Attribute | Value |
|---|---|
| Current coverage | 0% |
| Target | Precision > 0.80, False Positive Rate < 0.05 |
| Current component | None |

**Gap description:** No anomaly detection exists. Unusual transactions (unexpectedly large amounts, merchants in new categories, first-time merchant, unusual time/location) are not flagged.

**Migration path:**
1. Define `AnomalySignal` struct with anomaly type enum
2. Build statistical baseline per user: per-merchant amount distribution, per-category frequency, typical transaction time distribution
3. Train isolation forest or one-class SVM on normal transaction features
4. Export as CoreML tabular model
5. Create `AnomalyDetector` Swift class
6. Integrate as stage 11 in inference pipeline (low-latency, non-blocking)

**Effort:** M
**Risk:** Medium (false positive rate control is the main challenge; user-specific baseline requires sufficient history)

---

### Model 10 — Description Generator

| Attribute | Value |
|---|---|
| Current coverage | ~20% (FallbackGenerator produces formulaic output; AppleIntelligenceAdapter on limited devices) |
| Target | Natural language descriptions indistinguishable from human-written |
| Current component | `AppleIntelligenceAdapter`, `FallbackGenerator` |

**Gap description:** `FallbackGenerator` produces robotic descriptions. Apple Intelligence is not available on all device/region combinations. An on-device MLX LLM model can fill the gap for devices without Apple Intelligence.

**Migration path:**
1. Select a small MLX-compatible LLM (Phi-3 mini or similar, < 2 GB)
2. Fine-tune on (transaction_features → description) pairs
3. Build `MLXDescriptionGenerator` Swift class
4. Integrate into `DescriptionGenerator` fallback chain: AppleIntelligence → MLX → FallbackGenerator

**Effort:** L
**Risk:** High (MLX integration is new infrastructure; LLM memory footprint on older devices is a concern)

---

### Model 11 — Insight Generator

| Attribute | Value |
|---|---|
| Current coverage | ~40% (SpendingInsightEngine produces accurate but generic statistical insights) |
| Target | Personalized, narrative-quality financial insights |
| Current component | `SpendingInsightEngine` |

**Gap description:** `SpendingInsightEngine` produces factually accurate but template-driven insights ("You spent 23% more on dining this month"). An MLX LLM can produce narrative, context-aware insights grounded in the statistical data.

**Migration path:**
1. Define `InsightGenerationRequest` struct (statistical aggregates as context)
2. Build `MLXInsightGenerator` that accepts statistical context and produces narrative
3. Design prompting strategy to prevent hallucination (grounded generation only)
4. Integrate `SpendingInsightEngine` as the statistics provider
5. Wire `MLXInsightGenerator` as the narrative layer on top

**Effort:** M (reuses MLX infrastructure from Model 10)
**Risk:** Medium (hallucination prevention in financial domain requires careful prompting and output validation)

---

## Platform Capability Gaps

### Training Pipeline

| Attribute | Value |
|---|---|
| Current state | Does not exist |
| Target | `training/` directory with per-model Python scripts |
| Gap | No training data export, no model training scripts, no coremltools export scripts |
| Effort | L |
| Risk | High |

**Details:** There is no Python training infrastructure whatsoever. All 11 models need:
- `training/<model>/train.py` — training script
- `training/<model>/export.py` — CoreML/MLX export
- `training/<model>/benchmark.py` — evaluation
- `training/data/export.py` — labeled data export from GRDB
- `training/requirements.txt` — Python dependencies

---

### Dataset Generation

| Attribute | Value |
|---|---|
| Current state | Does not exist |
| Target | Labeled dataset of ≥ 50 examples per class per model |
| Gap | No labeling tooling, no export pipeline, no dataset versioning |
| Effort | L |
| Risk | Critical |

**Details:** Dataset quality is the single largest risk to the entire platform. Indian financial transaction narrations require domain expertise to label correctly. Initial dataset must come from:
1. Existing `RuleBasedCategorizer` output as weak labels (auto-labeled, low quality)
2. `MerchantAliasTable` entries as training anchors
3. Manual annotation of a representative sample (500–1000 transactions)
4. Synthetic augmentation (UPI VPA variations, amount masking, bank format variations)

---

### Evaluation Framework

| Attribute | Value |
|---|---|
| Current state | Does not exist |
| Target | Per-model benchmark.py + CI integration |
| Gap | No evaluation scripts, no golden transaction set, no regression testing |
| Effort | M |
| Risk | High |

**Details:** Without an evaluation framework, it is impossible to know if a new model version is better or worse than the current one. A golden transaction set of ~500 hand-labeled transactions must be created and checked into `training/data/golden_transactions.jsonl`.

---

### CoreML Export Pipeline

| Attribute | Value |
|---|---|
| Current state | Model 2 artifact exists but export script not documented |
| Target | Reproducible export script per model |
| Gap | No `export.py` scripts, no artifact versioning, no hash verification |
| Effort | S |
| Risk | Low |

---

### MLX Integration

| Attribute | Value |
|---|---|
| Current state | Does not exist |
| Target | `MLXRuntime` Swift module for on-device LLM inference |
| Gap | No MLX Swift package dependency, no model loading infrastructure |
| Effort | M |
| Risk | Medium |

---

### Personalization Layer

| Attribute | Value |
|---|---|
| Current state | Partial (PersonalizedClassifier with TF-IDF) |
| Target | Embedding-based kNN with ANN index |
| Gap | No embedding integration, linear scan performance issue at scale |
| Effort | M (depends on Model 7) |
| Risk | Medium |

---

### Feedback Collection

| Attribute | Value |
|---|---|
| Current state | Partial (Feedback module captures corrections) |
| Target | Full pipeline: capture → export → training data inclusion |
| Gap | No export pipeline from FeedbackStore to training data format |
| Effort | S |
| Risk | Low |

---

## Gap Priority Matrix

| Priority | Gap | Blocks |
|---|---|---|
| P0 | Evaluation Framework | Knowing if anything works |
| P0 | Dataset Generation | All model training |
| P1 | Training Pipeline | All model training |
| P1 | CoreML Export Pipeline | All model deployment |
| P2 | Model 1 (Merchant) | MerchantAliasTable replacement |
| P2 | Model 2 (Category) extensions | Subcategory, evaluation |
| P2 | ModelRegistry wiring | Version-pinned deployment |
| P3 | Models 3, 4, 5 (Intent, Recurring, Subscription) | Behavioral intelligence |
| P3 | Model 6 (Income) | Income analytics |
| P4 | Model 7 (Embeddings) | Models 8, personalization |
| P4 | MLX Integration | Models 10, 11 |
| P5 | Models 8, 9, 10, 11 | Full platform |
