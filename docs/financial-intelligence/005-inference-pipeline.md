---
doc: 005-inference-pipeline
version: 0.1.0
status: Draft
date: 2026-06-02
---

# Inference Pipeline — FinanceIntelligence Platform

## Purpose

Define the complete stage-by-stage inference pipeline that transforms a raw transaction into a fully enriched `TransactionIntelligence` result. This document specifies the input/output contract at each stage, parallelization strategy, fallback behavior, latency budget, and error handling policy.

---

## Pipeline Overview

```
RawTransaction
      │
      ▼
[Stage 0] Deterministic Policy Gate
      │ NormalizedTransaction | .rejected
      ▼
[Stage 1] Structural Extraction
      │ StructuredTransaction
      ▼
[Stage 2] Merchant Recognition           ◄── Model 1 (CoreML NLModel)
      │ + MerchantPrediction
      ▼
[Stage 3] Category + Intent              ◄── Models 2+3 (parallel)
      │ + CategoryPrediction + IntentPrediction
      ▼
[Stage 4] Income Classification          ◄── Model 6 (CoreML NLModel, credits only)
      │ + IncomePrediction?
      ▼
[Stage 5] Embedding Generation           ◄── Model 7 (CoreML)
      │ + EmbeddingVector
      ▼
[Stage 6] Personalization Overlay        ◄── PersonalizedClassifier (kNN)
      │ Possibly corrects category, intent, income predictions
      ▼
[Stage 7] Recurring + Subscription       ◄── Models 4+5 (parallel, sequence-dependent)
      │ + RecurringPrediction + SubscriptionPrediction
      ▼
[Stage 8] Anomaly Detection              ◄── Model 9 (CoreML Tabular)
      │ + [AnomalySignal]
      ▼
[Stage 9] Assemble TransactionIntelligence
      │ TransactionIntelligence
      ▼
[Async Stage A] Link Prediction          ◄── Model 8 (MLX)
[Async Stage B] Description Generation  ◄── Model 10 (MLX LLM)
[Async Stage C] Insight Generation      ◄── Model 11 (MLX LLM, batch)
```

---

## Stage Specifications

### Stage 0 — Deterministic Policy Gate

**Input:** `RawTransaction`
**Output:** `NormalizedTransaction` or rejection

**Rules (all must pass):**
1. Amount must be > 0
2. Date must be parseable and within allowed range (not future > 1 day)
3. Account number must be non-empty after normalization
4. Narration must be non-empty (minimum 3 characters)
5. Direction must be determinable (CR / DR)

**On rejection:** Return `IntelligencePipelineResult.rejected(reason: String)`. Do not proceed. Log to `GRDBIntelligenceLogger`.

**Latency target:** < 1 ms (no I/O, no model calls)

---

### Stage 1 — Structural Extraction

**Input:** `NormalizedTransaction`
**Output:** `StructuredTransaction`

**Operations:**
- `UPIDescriptionParser`: extract VPA, gateway, reference ID
- `PaymentChannelClassifier`: classify UPI / NEFT / RTGS / IMPS / NACH / ECS / Card / Cash
- `AccountExtractor`: extract beneficiary account number / IFSC
- `RuleEngine.apply()`: structural rules only (no category/intent mutations allowed)

**Hardening notes:**
- `UPIDescriptionParser` returns `nil` fields gracefully if pattern does not match
- All extracted fields are Optional in `StructuredTransaction`
- Rules that mutate category or intent are prohibited at this stage

**Latency target:** < 5 ms

---

### Stage 2 — Merchant Recognition

**Input:** `StructuredTransaction`
**Output:** `StructuredTransaction` + `MerchantPrediction`

**Model:** `CoreMLMerchantRecognizer` (Model 1 — NLModel text classifier)

**Input feature construction:**
```
feature_string = narration
               + (upi_vpa ?? "")
               + (payment_channel.rawValue)
```

**Fallback chain:**
1. CoreML Model 1 (primary)
2. `MerchantAliasTable` lookup (fallback — deprecated, kept during migration)
3. UPI VPA domain extraction (heuristic)
4. Raw narration first token (last resort)

**Confidence threshold:** 0.50 (low threshold — prefer a guess over Unknown)

**Latency target:** < 20 ms

---

### Stage 3 — Category + Intent Classification (Parallel)

**Input:** `StructuredTransaction` + `MerchantPrediction`
**Output:** `CategoryPrediction` + `IntentPrediction`

Models 2 and 3 run **concurrently** via `async let`.

```swift
async let categoryResult = categoryClassifier.classify(categoryInput)
async let intentResult   = intentClassifier.classify(intentInput)
let (category, intent)   = try await (categoryResult, intentResult)
```

**Category input feature construction:**
```
feature_string = narration + " " + (merchantName ?? "") + " " + (paymentChannel.rawValue)
```

**Intent input feature construction:**
```
feature_string = narration + " " + (category.rawValue) + " " + (merchantName ?? "")
```

**Fallback chain (Category):**
1. CoreML Model 2
2. `RuleBasedCategorizer` (fallback — deprecated, kept during migration)
3. `.other` (final fallback)

**Fallback chain (Intent):**
1. CoreML Model 3
2. Category-to-intent mapping table (structural heuristic, not ML)
3. `.unknown` (final fallback)

**Latency target:** < 20 ms (parallel, bounded by slower of the two)

---

### Stage 4 — Income Classification

**Input:** `StructuredTransaction`, `CategoryPrediction`
**Output:** `IncomePrediction?`

**Condition:** Only executes if `direction == .credit`.

**Model:** `CoreMLIncomeClassifier` (Model 6 — NLModel)

**Fallback:** Returns `nil` if model unavailable (income detection is additive, not required).

**Latency target:** < 15 ms

---

### Stage 5 — Embedding Generation

**Input:** `StructuredTransaction.narration`
**Output:** `EmbeddingVector` (Float32[128])

**Model:** `CoreMLEmbeddingGenerator` (Model 7)

**Fallback:** Returns `nil` embedding if model unavailable. Downstream models that require embeddings must handle nil gracefully.

**Storage:** Embedding persisted asynchronously to `transaction_embeddings` table after pipeline completes. Not on the critical path.

**Latency target:** < 30 ms

---

### Stage 6 — Personalization Overlay

**Input:** `CategoryPrediction`, `IntentPrediction`, `IncomePrediction`, `EmbeddingVector`
**Output:** Possibly-corrected predictions with `source: .personalized`

**Logic:**
```
IF embedding != nil:
    kNN search over FeedbackStore embeddings
    IF nearest neighbor distance < threshold AND label_confidence > 0.70:
        replace base prediction with stored correction
        set source = .personalized
ELSE:
    TF-IDF fallback for kNN (legacy path)
```

**Side effect:** None. Does not write to FeedbackStore.
**Latency target:** < 10 ms (ANN lookup with pre-built index)

---

### Stage 7 — Recurring + Subscription Detection (Parallel)

**Input:** `StructuredTransaction`, `MerchantPrediction`, historical transaction sequence
**Output:** `RecurringPrediction` + `SubscriptionPrediction`

**Sequence fetch:** Query last 90 days of transactions from same merchant before running Model 4. This query must be fast (indexed by merchant + date).

```swift
async let recurringResult      = recurringDetector.detect(sequence)
async let subscriptionResult   = subscriptionDetector.detect(subscriptionInput)
let (recurring, subscription)  = try await (recurringResult, subscriptionResult)
```

**Subscription detector input:** `merchantName + recurringResult + amount`

**Latency target:** < 30 ms (including DB sequence query)

---

### Stage 8 — Anomaly Detection

**Input:** `TransactionFeatures`, `UserHistory`
**Output:** `[AnomalySignal]`

**UserHistory source:** Materialized view cached in memory (refreshed per import session). Not computed per-transaction.

**Model:** `CoreMLAnomalyDetector` (Model 9 — Isolation Forest or One-Class SVM via CoreML tabular)

**Multiple anomaly types may fire per transaction.** All signals are collected into an array.

**Latency target:** < 20 ms

---

### Stage 9 — Assembly

**Input:** All stage outputs
**Output:** `TransactionIntelligence`

Assembles the final struct, records `pipelineLatencyMs`, collects model versions from registry, and returns to caller.

**Logging:** Full result logged to `GRDBIntelligenceLogger` asynchronously (non-blocking).

---

## Asynchronous Post-Processing Stages

These stages fire after the transaction is persisted. They do not block the import pipeline.

### Async Stage A — Link Prediction

**Trigger:** Per-transaction, after graph enrichment
**Model:** MLX Link Predictor (Model 8)
**Output:** Suggested graph edges written to `KnowledgeGraph` if confidence > 0.75

### Async Stage B — Description Generation

**Trigger:** Per-transaction, batched (max 50 per batch)
**Model:** MLX LLM (Model 10)
**Output:** Human-readable description written to `transactions.intelligence_description`

**Priority:** Low. Runs only when device is idle (low thermal state, not on battery < 20%).

### Async Stage C — Insight Generation

**Trigger:** Monthly (end of month) or on-demand
**Model:** MLX LLM (Model 11) with `SpendingInsightEngine` statistics as context
**Output:** `[FinancialInsight]` persisted to `financial_insights` table

---

## Fallback Behavior Summary

| Stage | Primary | Fallback 1 | Fallback 2 | On Total Failure |
|---|---|---|---|---|
| Merchant | CoreML Model 1 | MerchantAliasTable | VPA heuristic | Raw narration token |
| Category | CoreML Model 2 | RuleBasedCategorizer | — | `.other` |
| Intent | CoreML Model 3 | Category→Intent map | — | `.unknown` |
| Income | CoreML Model 6 | — | — | `nil` (skip) |
| Embedding | CoreML Model 7 | — | — | `nil` (skip) |
| Recurring | CoreML Model 4 | Heuristic (±30 day) | — | `isRecurring: false` |
| Subscription | Hybrid Model 5 | Recurring + merchant match | — | `isSubscription: false` |
| Anomaly | CoreML Model 9 | Statistical z-score | — | empty array |

---

## Latency Budget

| Stage | Budget | Actual (P95, target) |
|---|---|---|
| Stage 0 | 1 ms | — |
| Stage 1 | 5 ms | — |
| Stage 2 | 20 ms | — |
| Stage 3 | 20 ms | — |
| Stage 4 | 15 ms | — |
| Stage 5 | 30 ms | — |
| Stage 6 | 10 ms | — |
| Stage 7 | 30 ms | — |
| Stage 8 | 20 ms | — |
| Stage 9 | 2 ms | — |
| **Total** | **153 ms** | **< 200 ms target** |

P95 latency will be measured using the evaluation harness once all models are deployed.

---

## Error Handling Policy

- **Model load failure:** Log fatal event; use fallback implementation; never crash.
- **Inference timeout** (> 500 ms per model): Cancel inference, use fallback, log warning.
- **Unexpected model output** (out-of-vocabulary label): Log warning, map to fallback label.
- **DB query failure in Stage 7** (sequence fetch): Proceed with empty sequence; log warning.
- **Memory pressure notification:** Unload optional models (MLX LLMs); keep CoreML models loaded.

---

## Pipeline Entry Point

```swift
// IntelligencePipeline.swift
public final class IntelligencePipeline {
    public func process(_ transaction: RawTransaction) async -> IntelligencePipelineResult
    public func processBatch(_ transactions: [RawTransaction]) async -> [IntelligencePipelineResult]
}

public enum IntelligencePipelineResult {
    case enriched(TransactionIntelligence)
    case rejected(reason: String)
    case failed(error: IntelligenceError)
}
```

---

## Testing Strategy

- **Unit tests:** Each stage tested in isolation with mock dependencies.
- **Integration tests:** Full pipeline tested against golden transaction fixtures in `FinanceTesting`.
- **Benchmark tests:** `benchmark.py` runs 500 labeled transactions through Swift CLI harness; measures F1 + latency.
- **Regression tests:** Golden output compared against stored fixture on every CI build.
