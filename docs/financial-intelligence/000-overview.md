---
doc: 000-overview
version: 0.1.0
status: Draft
date: 2026-06-02
---

# FinanceOS Financial Intelligence Platform — Overview

## Purpose

The Financial Intelligence Platform is the ML-powered analysis layer that transforms raw bank transaction narrations into structured, enriched, actionable financial intelligence. It sits between the ingestion pipeline (FinanceParsers) and the presentation layer (FinanceUI), operating entirely on-device without any cloud inference.

The platform replaces a fragile patchwork of keyword rules, regex patterns, and hardcoded merchant aliases with a suite of 11 trained ML models that generalize across Indian financial transaction vocabulary, UPI payment channels, and diverse bank narration formats.

### Why It Exists

Indian bank statement narrations are highly heterogeneous:

- HDFC formats: `NEFT/RTGS-MERCHANT NAME-REF12345`
- ICICI formats: `UPI/CR/123456/GooglePay/user@okicici/DESC`
- SBI formats: `TO TRANSFER-IMPS-REF/MERCHANT/IFSC`
- UPI VPA patterns: `merchant@upi`, `9876543210@paytm`, `merchant.name@okaxis`

Rule-based systems break on unseen formats, require manual maintenance per bank, and cannot infer intent or detect recurring patterns reliably. The ML platform learns these patterns from labeled data and generalizes.

### What It Replaces

| Existing Component | Replacement |
|---|---|
| `RuleBasedCategorizer` (keyword rules) | CoreML text classifier (Model 2) |
| `MerchantNormalizer` + `MerchantAliasTable` (~40 merchants) | Merchant recognition model (Model 1) |
| Manual recurring detection heuristics | Recurring pattern model (Model 4) |
| `SpendingInsightEngine` (statistical only) | Insight generation model (Model 11) |
| `DescriptionGenerator` (template-based) | Description generation model (Model 10) |

Existing components that are kept and extended: `KnowledgeGraph`, `EntityResolution`, `PersonalizedClassifier`, `GRDBIntelligenceLogger`, `Feedback`, `Registry`.

---

## Five-Layer Architecture

```
+------------------------------------------------------------------+
| Layer 1: Deterministic Policy                                    |
|  - Zero-amount filter, duplicate gate, currency normalization    |
|  - Hard rules that must never be overridden by ML               |
+------------------------------------------------------------------+
          |
          v
+------------------------------------------------------------------+
| Layer 2: Configurable Rules                                      |
|  - UPI prefix detection (structured parse, not ML)              |
|  - Payment channel classification (UPI/NEFT/RTGS/IMPS/NACH/ECS) |
|  - Account number extraction                                     |
|  - RuleEngine with BuiltInRules (retained, scoped to structure)  |
+------------------------------------------------------------------+
          |
          v
+------------------------------------------------------------------+
| Layer 3: ML Inference                                            |
|  - 11 CoreML/MLX models (see table below)                       |
|  - Feature extraction → model inference → confidence scoring    |
|  - PersonalizedClassifier overlay (kNN from user corrections)   |
+------------------------------------------------------------------+
          |
          v
+------------------------------------------------------------------+
| Layer 4: Post-Processing                                         |
|  - Knowledge Graph enrichment (GraphBuilder, GraphStore)        |
|  - Entity resolution (PersonResolver, PersonDeduplicator)       |
|  - Anomaly signal aggregation                                    |
|  - Insight synthesis (SpendingInsightEngine + Model 11)         |
+------------------------------------------------------------------+
          |
          v
+------------------------------------------------------------------+
| Layer 5: Feedback + Evaluation                                   |
|  - User correction capture (Feedback module)                    |
|  - PersonalizedClassifier retraining trigger                    |
|  - GRDBIntelligenceLogger observability                         |
|  - Evaluation harness (benchmark.py scripts)                    |
+------------------------------------------------------------------+
```

---

## The 11 Models

| # | Model | Input | Output | Architecture | Status |
|---|---|---|---|---|---|
| 1 | Merchant Recognition | Narration + UPI VPA | Merchant name + confidence | Text classifier (NLModel) | Planned |
| 2 | Category Classifier | Narration + merchant | Category + subcategory | NLModel (CoreML) | Deployed (extend) |
| 3 | Intent Classifier | Narration + category | Intent enum | NLModel (CoreML) | Planned |
| 4 | Recurring Detector | Transaction sequence | RecurringPattern | Tabular regressor | Planned |
| 5 | Subscription Detector | Merchant + amount + cadence | SubscriptionPrediction | Rule+ML hybrid | Planned |
| 6 | Income Classifier | Narration + amount direction | IncomePrediction | NLModel (CoreML) | Planned |
| 7 | Embedding Model | Narration text | Float32[128] embedding | Sentence encoder (MLX) | Planned |
| 8 | Link Prediction | Entity pairs from KG | LinkPrediction score | GNN (MLX) | Planned |
| 9 | Anomaly Detector | Transaction + user history | AnomalySignal | Statistical + ML | Planned |
| 10 | Description Generator | Transaction features | Human-readable string | LLM (MLX, on-device) | Partial (FallbackGenerator) |
| 11 | Insight Generator | Aggregated spending data | FinancialInsight array | LLM (MLX, on-device) | Partial (SpendingInsightEngine) |

Target accuracy commitments:
- Category Macro F1 > 0.92
- Intent Macro F1 > 0.95
- Merchant Top-1 Accuracy > 0.95

---

## Offline-First Principle

All inference runs on-device. This is a hard architectural constraint, not a preference.

Rationale:
1. User financial data never leaves the device
2. No dependency on network availability for core features
3. No per-inference API cost
4. Consistent latency regardless of connectivity

Implications for model design:
- CoreML models must fit within iOS/macOS memory budget (< 50 MB per model, < 150 MB total)
- MLX models (LLM-based) are optional/deferred features, gated on device capability
- No model calls external APIs during inference
- Training happens offline (Python pipeline); only model artifacts ship to the app

---

## Self-Learning Architecture

The platform improves over time through a feedback loop that never requires cloud connectivity.

```
User Correction
      |
      v
FeedbackStore (GRDB)
      |
      v
PersonalizedClassifier
  (kNN overlay on CoreML base model)
      |
      v
Corrected Prediction
      |
      v
Evaluation Logger (GRDBIntelligenceLogger)
      |
      v
[Export for retraining — manual trigger]
      |
      v
Python training pipeline
      |
      v
New CoreML model artifact
      |
      v
ModelRegistry promotion
      |
      v
App bundle update (next release)
```

The kNN personalized classifier provides immediate improvement from user corrections within the same session, while full model retraining captures patterns across all users' corrections (if opted in) for the next app version.

---

## Phased Rollout Strategy

### Phase 1 — Foundation (Current Sprint)
- Harden existing `CoreMLCategorizer` (Model 2)
- Build training data export pipeline
- Create evaluation harness
- Document all existing modules (this doc set)

### Phase 2 — Merchant + Category ML (Next 2 Sprints)
- Train and deploy Merchant Recognition model (Model 1)
- Extend Category Classifier to subcategory level
- Replace `MerchantAliasTable` with Model 1 output
- A/B test vs. current `RuleBasedCategorizer`

### Phase 3 — Intent + Recurring (Sprint +3–4)
- Train Intent Classifier (Model 3)
- Train Recurring Detector (Model 4)
- Train Subscription Detector (Model 5)
- Integrate with KnowledgeGraph enrichment

### Phase 4 — Embeddings + Graph (Sprint +5–6)
- Train Embedding Model (Model 7)
- Train Link Prediction (Model 8)
- Integrate embeddings into KnowledgeGraph
- Enable semantic similarity search

### Phase 5 — Anomaly + Generative (Sprint +7–8)
- Train Anomaly Detector (Model 9)
- Deploy Income Classifier (Model 6)
- MLX integration for Description Generator (Model 10)
- MLX integration for Insight Generator (Model 11)

### Phase 6 — Evaluation + Hardening
- Full benchmark suite against golden transaction set
- Per-class evaluation for all models
- CI integration for regression testing
- ModelRegistry promotion workflow

---

## Key Design Decisions

1. **CoreML for classification, MLX for generation.** CoreML offers the best on-device latency and memory efficiency for text classification tasks. MLX is reserved for the generative models (10, 11) which require larger context windows.

2. **Python training pipeline, Swift inference only.** No CreateML GUI. All models are trained via Python scripts in `training/`, exported via `coremltools`, and registered in `model_registry.yaml`. The Swift layer only loads artifacts.

3. **PersonalizedClassifier as an overlay, not a replacement.** The base CoreML model provides calibrated predictions. User corrections are captured as labeled examples and applied via kNN without requiring model retraining.

4. **RuleEngine scoped to structural extraction, not semantics.** After the ML rollout, `RuleEngine` / `BuiltInRules` handle only deterministic structural tasks (payment channel parsing, account extraction). All semantic classification moves to ML.

5. **ModelRegistry as the single source of truth for model versioning.** No hardcoded model filenames in Swift. All model loading goes through `ModelRegistry` which maps logical names to artifact paths and validates hashes.
