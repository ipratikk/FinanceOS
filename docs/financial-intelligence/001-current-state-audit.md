---
doc: 001-current-state-audit
version: 0.1.0
status: Draft
date: 2026-06-02
---

# Current State Audit — FinanceIntelligence Package

## Purpose

This document audits every module in the existing `FinanceIntelligence` Swift package, documents what each does, identifies weaknesses, catalogs hardcoded values and magic numbers, and produces a disposition decision (Keep As-Is / Extend / Replace With ML / Deprecate) for each module.

---

## Package Location

`Packages/FinanceIntelligence/Sources/FinanceIntelligence/`

---

## Module Inventory

### 1. Categorization

#### `RuleBasedCategorizer`

**What it does:** Maps transaction narrations to `TransactionCategory` using keyword matching. Iterates over a list of `(keyword, category)` pairs and returns the first match. Falls back to `.other` when no keyword matches.

**Strengths:**
- Deterministic and debuggable
- Zero inference latency
- No model loading required

**Weaknesses:**
- Coverage depends entirely on keyword list completeness
- Cannot generalize to unseen narration patterns
- No subcategory support
- Keyword collisions (e.g., "AMAZON" matches both shopping and AWS)
- No confidence scoring; binary match/no-match
- Keyword list requires manual maintenance per bank format
- Estimated coverage: ~60% of real-world Indian transaction narrations

**Hardcoded values:**
```
// RuleBasedCategorizer.swift — keyword→category mapping table
// Approximately 80–120 keyword entries
// No source of truth; edited directly in Swift
```

**Disposition:** Replace With ML (Model 2 already partially deployed; complete replacement is Phase 2)

---

#### `CoreMLCategorizer`

**What it does:** Loads a `.mlmodel` (NLModel text classifier) and runs inference on transaction narration strings. Outputs a predicted `TransactionCategory` label and a confidence score from the model's posterior distribution.

**Strengths:**
- Already deployed and producing real predictions
- Generalizes to unseen narration patterns
- Confidence scores from NLModel are calibrated via softmax

**Weaknesses:**
- Trained only on macro-category labels (no subcategory)
- Training dataset not documented; no version pinning
- Model artifact filename hardcoded in Swift (`"TransactionCategoryClassifier"`)
- No fallback chain defined (crashes vs. graceful degradation unclear)
- No evaluation harness; F1 unknown on current production distribution
- Does not consume UPI-parsed structured fields (only raw narration string)
- No A/B test infrastructure to compare against `RuleBasedCategorizer`

**Hardcoded values:**
```swift
// CoreMLCategorizer.swift
let modelName = "TransactionCategoryClassifier"  // hardcoded artifact name
let confidenceThreshold = 0.65                    // magic number, no justification
```

**Disposition:** Extend (wire to ModelRegistry, add subcategory support, add evaluation harness)

---

### 2. Merchant

#### `MerchantNormalizer`

**What it does:** Takes a raw narration string and attempts to extract a canonical merchant name. Delegates to `MerchantAliasTable` for known merchants; applies regex stripping for UPI suffixes (`@upi`, `@oksbi`, etc.) for unknowns.

**Strengths:**
- Handles basic UPI VPA normalization correctly
- Fast (no model load)

**Weaknesses:**
- Canonical merchant list is ~40 entries — extremely incomplete
- Cannot recognize merchants not in the alias table
- Regex patterns for UPI VPA stripping are brittle (does not handle all gateway suffixes)
- Returns raw narration fragment as "merchant" for unknown transactions
- No confidence score; binary known/unknown

**Hardcoded values:**
```swift
// MerchantAliasTable.swift
// ~40 (alias, canonicalName) pairs, hardcoded in Swift source
// e.g., ("SWIGGY", "Swiggy"), ("ZOMATO", "Zomato"), ("AMZN", "Amazon")
```

**Disposition:** Replace With ML (Model 1 — Merchant Recognition)

---

#### `MerchantAliasTable`

**What it does:** Dictionary lookup from merchant alias string to canonical merchant name. Populated at compile time with ~40 entries.

**Weaknesses:**
- ~40 merchants covers a small fraction of Indian merchant ecosystem
- No partial matching (requires exact alias match after normalization)
- No alias learning from user corrections
- Version-locked to source code changes

**Disposition:** Replace With ML (will be superseded by Model 1 output and a KnowledgeGraph-backed merchant entity store)

---

### 3. Features / UPI

#### `UPIDescriptionParser`

**What it does:** Parses UPI payment narrations into structured fields using regex patterns. Extracts: UPI reference ID, sender/receiver VPA, payment gateway (GPay/PhonePe/Paytm/etc.), transaction type (CR/DR).

**Strengths:**
- Handles most standard UPI narration formats
- Structured output reduces ML feature burden
- Deterministic and fast

**Weaknesses:**
- Regex patterns hardcoded; brittle against new bank-specific UPI narration variants
- Gateway detection table needs regular updates as new gateways emerge
- Does not handle BBPS, Bharat QR, or FASTag narrations
- No confidence or parse-success signal exposed to callers

**Configuration:**
```swift
// MerchantGatewayConfig.swift
// merchant_gateways.json loaded at runtime — this is the correct pattern
// Coverage: GPay, PhonePe, Paytm, BHIM, Amazon Pay, WhatsApp Pay, Cred, Slice
// Missing: Jupiter, Fi, Navi, Groww Pay, several regional wallets
```

**Disposition:** Keep As-Is (extend gateway list; layer ML on top for cases where regex fails)

---

### 4. KnowledgeGraph

#### `GraphBuilder`

**What it does:** Constructs graph edges between Transaction, Merchant, Category, and Person entities after each import batch. Writes to GRDB via `GraphStore`.

**Strengths:**
- Correct architectural separation (builder vs. store vs. query)
- Batched writes implemented (post perf optimization in recent commits)

**Weaknesses:**
- Graph schema limited to 4 entity types; no embedding nodes yet
- No temporal edge weighting
- Link prediction requires manual query (no ML-assisted suggestion)

**Disposition:** Extend (add embedding nodes for Model 7; enable Link Prediction edges for Model 8)

---

#### `GraphStore`

**What it does:** GRDB persistence layer for the knowledge graph. Owns all INSERT/UPDATE/DELETE for graph entities and edges.

**Disposition:** Keep As-Is (stable, well-tested after batch perf optimization)

---

#### `GraphQueries`

**What it does:** Read-side queries for the knowledge graph. Supports: edges by entity, neighbors, path existence, entity lookup by type.

**Disposition:** Extend (add embedding similarity query support for Model 7)

---

### 5. EntityResolution

#### `PersonResolver`

**What it does:** Matches person entities across transactions using name similarity heuristics (edit distance + phonetic matching).

**Strengths:** Handles common Indian name spelling variations reasonably.

**Weaknesses:**
- Edit distance threshold is a magic number (`0.8`)
- No learning from user confirmations
- Does not use transaction context (amount, date, account) for disambiguation

**Disposition:** Extend (wire user confirmation feedback; lower priority)

---

#### `PersonDeduplicator`

**What it does:** Merges duplicate person entities in the knowledge graph. Runs as a batch job post-import.

**Disposition:** Keep As-Is

---

### 6. Personalization

#### `PersonalizedClassifier`

**What it does:** Maintains a labeled example store of user-corrected category predictions. At inference time, finds k-nearest neighbors in a simple feature space and returns a corrected label if confidence exceeds threshold.

**Strengths:**
- Provides immediate personalization without model retraining
- Correct architectural separation from base models

**Weaknesses:**
- Feature space is naive (TF-IDF over narration tokens)
- Does not use embeddings from Model 7
- kNN search is O(n) linear scan — will degrade at scale
- No eviction policy for stale corrections
- Confidence threshold magic number (`0.7`)

**Disposition:** Extend (replace TF-IDF with Model 7 embeddings; add ANN index for scale)

---

### 7. Insights

#### `SpendingInsightEngine`

**What it does:** Generates spending insights by computing statistical aggregates (monthly totals by category, MoM deltas, top merchants, etc.). Returns `TransactionInsight` array.

**Strengths:**
- Factually accurate (grounded in real transaction data)
- No hallucination risk (rule-based aggregation)
- Fast

**Weaknesses:**
- Insights are generic and templated, not personalized narratives
- No anomaly detection integration
- No goal-tracking awareness
- Cannot generate forward-looking projections

**Disposition:** Keep As-Is (extend with Model 11 narrative layer on top; statistical backbone remains)

---

### 8. Description Generation

#### `AppleIntelligenceAdapter`

**What it does:** Calls Apple Intelligence APIs (Writing Tools / on-device LLM) to generate human-readable transaction descriptions when available (iOS 18.1+/macOS 15.1+).

**Strengths:**
- Produces natural language output
- On-device, privacy-preserving

**Weaknesses:**
- Requires Apple Intelligence availability (not available on all devices/regions)
- No fallback quality guarantee
- Output not deterministic (varies per call)
- Not testable in CI

**Disposition:** Keep As-Is (supplemented by Model 10 MLX generator as primary fallback)

---

#### `FallbackGenerator`

**What it does:** Template-based description generator used when Apple Intelligence is unavailable. Constructs sentences from structured fields (`merchant + amount + category`).

**Weaknesses:**
- Output is robotic/formulaic
- No context-awareness (does not consider spending history or patterns)

**Disposition:** Replace With ML (Model 10 — Description Generator via MLX)

---

### 9. RuleEngine

#### `RuleEngine` + `BuiltInRules`

**What it does:** Applies a list of `Rule` objects to a transaction. Each rule has a predicate and an action (mutate transaction fields). `BuiltInRules` defines the default rule set including: tax deduction detection, salary credit detection, refund tagging, round-trip detection.

**Strengths:**
- Deterministic, auditable
- Correct for structural tasks (payment channel classification, account extraction)

**Weaknesses:**
- Was used for semantic classification (category, intent) — this must stop
- Rules are defined in Swift source; no external configuration
- No rule priority system (first-match wins, order-dependent behavior)
- No rule coverage metrics

**Disposition:** Keep As-Is (scoped to structural/deterministic rules only; remove all category/intent rules post-ML deployment)

---

### 10. Behavior

#### `SalaryAnalyzer`

**What it does:** Detects regular salary credits by analyzing transaction amounts, dates, and narration patterns (NEFT/NACH with employer patterns).

**Disposition:** Extend (integrate with Income Classifier Model 6 output)

---

#### `FinancialRoutineDetector`

**What it does:** Identifies recurring financial behaviors (e.g., monthly rent, weekly grocery shopping) from transaction sequences.

**Disposition:** Extend (integrate with Recurring Detector Model 4 output)

---

#### `CashflowAnalyzer`

**What it does:** Computes net cashflow by period, categorizes inflow vs. outflow by source.

**Disposition:** Keep As-Is

---

### 11. Observability

#### `GRDBIntelligenceLogger`

**What it does:** Persists intelligence pipeline events (predictions, corrections, latency metrics) to GRDB for debugging and evaluation.

**Strengths:**
- Already integrated into pipeline
- Enables offline evaluation replay

**Weaknesses:**
- Log schema not versioned
- No query API for evaluation harness to consume logs
- No log rotation / pruning policy

**Disposition:** Extend (add query API for evaluation harness; add log schema versioning)

---

### 12. Feedback

**What it does:** Captures user correction events (original prediction, corrected label, transaction ID, timestamp). Stores in GRDB.

**Disposition:** Keep As-Is (extend to feed PersonalizedClassifier training data export)

---

### 13. Registry

**What it does:** `ModelRegistry` protocol and `LocalModelRegistry` implementation for loading CoreML model artifacts by name.

**Current state:** Partially implemented. `LocalModelRegistry` loads models by filename; no version pinning, no hash validation.

**Disposition:** Extend (see `007-model-registry.md` for full specification)

---

### 14. Recurring

**What it does:** `RecurringDetector` and `PatternAnalyzer`. Detects recurring transactions by clustering on (merchant, amount, cadence).

**Weaknesses:**
- Cadence detection is purely heuristic (7-day, 30-day windows hardcoded)
- No ML-based sequence modeling
- Amount tolerance is a magic number (`±5%`)
- Cannot detect irregular-but-recurring patterns (e.g., quarterly insurance)

**Hardcoded magic numbers:**
```swift
let cadenceWindows: [Int] = [7, 14, 30, 90]   // days
let amountTolerance: Double = 0.05              // ±5%
let minOccurrences: Int = 2                     // minimum recurrences to qualify
```

**Disposition:** Replace With ML (Model 4 — Recurring Detector)

---

### 15. Relationships

**What it does:** `RelationshipEngine` builds and queries person-to-person and person-to-merchant relationships from transaction data.

**Disposition:** Keep As-Is (extend with Link Prediction Model 8 output)

---

## Summary Disposition Table

| Module | Disposition | Notes |
|---|---|---|
| RuleBasedCategorizer | Replace With ML | Phase 2 |
| CoreMLCategorizer | Extend | Wire to registry; add subcategory |
| MerchantNormalizer | Replace With ML | Phase 2 |
| MerchantAliasTable | Replace With ML | Phase 2 |
| UPIDescriptionParser | Keep As-Is | Extend gateway list |
| GraphBuilder | Extend | Add embedding nodes |
| GraphStore | Keep As-Is | Stable |
| GraphQueries | Extend | Add similarity queries |
| PersonResolver | Extend | Lower priority |
| PersonDeduplicator | Keep As-Is | Stable |
| PersonalizedClassifier | Extend | Use Model 7 embeddings |
| SpendingInsightEngine | Keep As-Is | Add Model 11 on top |
| AppleIntelligenceAdapter | Keep As-Is | Supplemented by Model 10 |
| FallbackGenerator | Replace With ML | Model 10 |
| RuleEngine + BuiltInRules | Keep As-Is | Scope to structural only |
| SalaryAnalyzer | Extend | Integrate Model 6 |
| FinancialRoutineDetector | Extend | Integrate Model 4 |
| CashflowAnalyzer | Keep As-Is | Stable |
| GRDBIntelligenceLogger | Extend | Add query API |
| Feedback | Keep As-Is | Minor extension |
| Registry (ModelRegistry) | Extend | Full spec in 007 |
| RecurringDetector | Replace With ML | Model 4 |
| PatternAnalyzer | Replace With ML | Model 4 |
| RelationshipEngine | Keep As-Is | Extend with Model 8 |

---

## Critical Gaps Identified

1. **No evaluation harness.** There is no code to measure F1, precision, recall, or accuracy on any existing component. This is the most critical gap — we cannot prove the ML models are better than the rules without it.

2. **No training data pipeline.** There is no export mechanism to produce labeled training data from the GRDB transaction store. All existing "training" data is implicit in the keyword rules.

3. **No model versioning.** `CoreMLCategorizer` hardcodes the model filename. `ModelRegistry` is partially implemented but not enforced.

4. **Uncalibrated confidence scores.** The `CoreMLCategorizer` confidence threshold (`0.65`) has no documented justification. There is no isotonic regression or temperature scaling applied post-training.

5. **Missing evaluation harness for RuleBasedCategorizer.** We do not know its actual precision/recall on the real production transaction distribution. Phase 2 A/B testing requires this baseline.

6. **No regression testing.** There is no golden transaction set that would catch regressions in categorization accuracy between releases.
