# FinanceOS Intelligence Pipeline — Implementation Plan

> **Status:** Active — reference this before any changes to the intelligence pipeline.  
> **Companion:** `reports/intelligence-pipeline-audit-2026-05-31.md`  
> **Principle:** Make the current intelligence layer measurable before making it more intelligent.

---

## 1. Implementation thesis

Do **not** start by replacing every heuristic with ML.

The first priority is to make the current pipeline **observable, reproducible, testable, and configurable**. Only after that should brittle heuristics be migrated to ML models.

The correct sequence is:

1. Freeze and instrument the existing behavior.
2. Remove misleading user-facing confidence scores.
3. Add evaluation and regression infrastructure.
4. Move magic numbers into configuration.
5. Add model/config/version provenance.
6. Clean up schema and feedback loops.
7. Replace high-risk heuristics with ML only after labels and evaluation exist.

The target state is an intelligence system with five clean layers:

```text
Deterministic Policy Layer
        ↓
Configurable Rules Layer
        ↓
ML Inference Layer
        ↓
Post-processing / Graph / Insights Layer
        ↓
Feedback + Evaluation Layer
```

---

## 2. Priority overview

### P0 — must be implemented first

These fix trust, correctness, and auditability risks.

| Priority | Workstream | Core outcome |
|----------|-----------|--------------|
| P0.1 | Suppress or reframe uncalibrated confidence | Users no longer see fake precision like `0.78 confidence` |
| P0.2 | Add structured inference logging | Every transaction records which path fired: rule, kNN, NLModel, fallback |
| P0.3 | Add held-out evaluation for kNN | Stop reporting training-set accuracy as if it were real accuracy |
| P0.4 | Add model metadata registry | Every model has version, training size, eval metrics, timestamp |
| P0.5 | Add golden transaction benchmark | Regression tests catch categorization/parser breakage |

### P1 — should follow immediately after P0

| Priority | Workstream | Core outcome |
|----------|-----------|--------------|
| P1.1 | Extract magic numbers to configuration | No critical threshold is buried inline |
| P1.2 | Move VPA gateway tokens to JSON config | Payment gateway updates no longer require code changes |
| P1.3 | Add relationship debug info | Relationship labels become explainable and debuggable |
| P1.4 | Add recurring/insight threshold config | Recurring and insight heuristics become tunable |
| P1.5 | Write `resolvedPersonId` to transaction rows | Dead schema column becomes useful or can later be removed |

### P2 — architecture cleanup

| Priority | Workstream | Core outcome |
|----------|-----------|--------------|
| P2.1 | Deprecate `LocalTransactionLearner` | One personalized classifier instead of two divergent kNN systems |
| P2.2 | Add feedback store for insights and relationships | Future ML has labels and implicit quality signals |
| P2.3 | Add fuzzy person deduplication | Reduce duplicate people caused by narration artifacts |
| P2.4 | Add `lastEnrichedAt` and enrichment provenance | Reprocessing becomes safe and selective |
| P2.5 | Protect user-corrected merchant names | Intelligence re-runs do not overwrite user corrections |

### Strategic ML work

| Priority | ML system | Replace |
|----------|-----------|---------|
| S1 | Person-vs-merchant classifier | `businessNameKeywords` |
| S2 | Relationship classifier | Additive hardcoded relationship weights |
| S3 | Personalized anomaly detection | Static 2σ / 3σ insight thresholds |
| S4 | Probabilistic recurring detector | Fixed cadence tolerance windows |

---

## 3. Target architecture

### 3.1 Deterministic policy layer

Keep here:
- amount normalization in minor units
- date/currency normalization
- bank parser structural parsing
- UPI prefix parsing
- phone-number VPA structural detection
- BILLPAY card-last4 extraction
- user correction override
- schema validation
- idempotency and audit logging

Owner modules:
```
FinanceParsers/
Features/UPIDescriptionParser.swift
MerchantNormalization/MerchantNormalizer.swift
Persistence/
Corrections/UserCorrectionStore.swift
```

### 3.2 Configurable rules layer

Move here:
- rule confidence threshold (currently `0.92` inline in `TransactionIntelligenceServiceImpl.swift:169`)
- kNN confidence threshold (currently `0.70` in `PersonalizedClassifier.swift:27`)
- relationship confidence cutoff (currently `0.40` in `RelationshipEngine.swift`)
- post-salary timing window (7 days)
- round amount divisor (₹500 = 50,000 minor units)
- recurring min occurrences
- recurring cadence tolerances
- subscription CV threshold (0.15)
- spike/anomaly multipliers (2σ / 3σ)
- graph edge weight increment/cap
- VPA gateway token list

New module:
```
FinanceIntelligence/Configuration/
  IntelligenceServiceConfiguration.swift
  IntelligenceConfigLoader.swift
  merchant_gateways.json
```

### 3.3 ML inference layer

Current:
```
Learning/PersonalizedClassifier.swift
Categorization/CoreMLCategorizer.swift
Learning/LocalTransactionLearner.swift         ← deprecate
```

Target:
```
Learning/PersonalizedClassifier.swift
Categorization/CoreMLCategorizer.swift
Disambiguation/PersonMerchantClassifier.swift  ← future S1
Relationships/RelationshipMLClassifier.swift   ← future S2
Insights/PersonalizedAnomalyDetector.swift     ← future S3
Recurring/ProbabilisticCadenceModel.swift      ← future S4
```

### 3.4 Post-processing layer

Target changes:
- keep graph building deterministic
- make recurring detection hybrid
- make relationship inference explainable now, ML-backed later (S2)
- insight confidence remains internal-only until calibrated
- add reason codes to all user-facing intelligence

### 3.5 Feedback and evaluation layer

**This is the largest missing layer.** Add:

```
Evaluation/
  GoldenTransactionBenchmark.swift
  ClassificationEvaluator.swift
  RecurringEvaluator.swift
  RelationshipEvaluator.swift

Observability/
  IntelligenceLogger.swift
  IntelligenceEvent.swift
  IntelligenceDebugExporter.swift

Registry/
  ModelRegistry.swift
  ModelMetadata.swift

Feedback/
  FeedbackStore.swift
  FeedbackEvent.swift
```

---

## 4. Database and schema changes

### 4.1 Add inference event table

```sql
CREATE TABLE intelligence_inference_events (
    id TEXT PRIMARY KEY,
    transaction_id TEXT,
    stage TEXT NOT NULL,
    source TEXT NOT NULL,
    rule_id TEXT,
    model_id TEXT,
    model_version TEXT,
    config_version TEXT,
    input_hash TEXT,
    output_label TEXT,
    output_intent TEXT,
    confidence REAL,
    confidence_kind TEXT NOT NULL,
    debug_json TEXT,
    created_at TEXT NOT NULL
);
```

`confidence_kind` values (use these — never treat uncalibrated as probability):
```
deterministic
calibrated_probability
uncalibrated_score
heuristic_ordinal
not_applicable
```

### 4.2 Add model metadata table

```sql
CREATE TABLE intelligence_model_metadata (
    id TEXT PRIMARY KEY,
    model_name TEXT NOT NULL,
    model_type TEXT NOT NULL,
    model_version TEXT NOT NULL,
    trained_at TEXT NOT NULL,
    training_example_count INTEGER NOT NULL,
    validation_example_count INTEGER,
    feature_version TEXT,
    config_version TEXT,
    accuracy REAL,
    precision_macro REAL,
    recall_macro REAL,
    f1_macro REAL,
    brier_score REAL,
    expected_calibration_error REAL,
    confusion_matrix_json TEXT,
    training_data_hash TEXT,
    notes TEXT
);
```

Applies immediately to `PersonalizedClassifier` and `CoreMLCategorizer`. Later extends to all future ML models.

### 4.3 Add enrichment provenance to transactions

```sql
ALTER TABLE transactions ADD COLUMN last_enriched_at TEXT;
ALTER TABLE transactions ADD COLUMN intelligence_source TEXT;
ALTER TABLE transactions ADD COLUMN intelligence_model_version TEXT;
ALTER TABLE transactions ADD COLUMN intelligence_config_version TEXT;
ALTER TABLE transactions ADD COLUMN is_user_corrected_merchant INTEGER DEFAULT 0;
```

`resolvedPersonId` already exists in schema (added in v10 migration) — start writing to it or remove it.

### 4.4 Add feedback event table

```sql
CREATE TABLE intelligence_feedback_events (
    id TEXT PRIMARY KEY,
    event_type TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    transaction_id TEXT,
    old_value TEXT,
    new_value TEXT,
    source TEXT,
    model_version TEXT,
    config_version TEXT,
    metadata_json TEXT,
    created_at TEXT NOT NULL
);
```

Supported event types:
```
category_corrected        merchant_corrected
person_merged             person_renamed
relationship_confirmed    relationship_rejected    relationship_corrected
recurring_confirmed       recurring_rejected
insight_opened            insight_dismissed        insight_ignored    insight_action_taken
```

---

## 5. Core type changes

### 5.1 Expand `CategoryPrediction`

```swift
struct CategoryPrediction: Codable, Equatable {
    let categoryId: String
    let intentId: String?
    let confidence: Double?
    let confidenceKind: ConfidenceKind
    let source: IntelligenceSource
    let modelVersion: String?
    let ruleId: String?
    let configVersion: String?
    let reasonCodes: [ReasonCode]
}

enum ConfidenceKind: String, Codable {
    case deterministic
    case calibratedProbability
    case uncalibratedScore
    case heuristicOrdinal
    case notApplicable
}

enum IntelligenceSource: Codable, Equatable {
    case userCorrection
    case structuralRule
    case personalizedKNN
    case coreMLNLModel
    case fallbackRule
    case manual
}

struct ReasonCode: Codable, Equatable {
    let code: String
    let message: String
    let strength: Double?
    let source: String
}
```

Example reason codes:
```
upi_phone_vpa_detected          merchant_gateway_token_matched
salary_prefix_detected          knn_nearest_neighbors_matched
nlmodel_text_classified         user_correction_override
```

### 5.2 Add `RelationshipDebugInfo`

```swift
struct RelationshipDebugInfo: Codable, Equatable {
    let personId: String
    let candidateType: RelationshipType
    let confidence: Double
    let confidenceKind: ConfidenceKind
    let evidence: [RelationshipEvidence]
    let excludedByRules: [String]
    let configVersion: String
}

struct RelationshipEvidence: Codable, Equatable {
    let code: String
    let value: String
    let weight: Double?
}
```

Example evidence codes:
```
monthly_cadence_detected        post_salary_payment_detected
round_amount_detected           rent_keyword_detected
high_debit_to_credit_ratio      dominant_credit_flow
insufficient_transaction_count  credit_card_payment_exclusion
```

### 5.3 Add `RecurringPatternDebugInfo`

```swift
struct RecurringPatternDebugInfo: Codable, Equatable {
    let merchantKey: String
    let observedIntervals: [Int]
    let candidateCadence: RecurringCadence
    let toleranceDays: Int
    let occurrenceCount: Int
    let amountCoefficientOfVariation: Double?
    let confidence: Double
    let confidenceKind: ConfidenceKind
    let configVersion: String
}
```

---

## 6. Configuration implementation

### `IntelligenceServiceConfiguration` shape

```swift
struct IntelligenceServiceConfiguration: Codable, Equatable {
    let version: String
    let classification: ClassificationConfig
    let relationship: RelationshipConfig
    let recurring: RecurringConfig
    let insight: InsightConfig
    let graph: GraphConfig
}
```

**Default values must exactly match current inline values:**

```swift
extension IntelligenceServiceConfiguration {
    static let defaultV1 = IntelligenceServiceConfiguration(
        version: "2026-05-31.v1",
        classification: ClassificationConfig(
            ruleConfidenceThreshold: 0.92,
            knnConfidenceThreshold: 0.70,
            nlModelConfidenceThreshold: nil
        ),
        relationship: RelationshipConfig(
            minConfidence: 0.40,
            postSalaryWindowDays: 7,
            roundAmountGranularityMinorUnits: 50_000,
            minTransactionsForInference: 2
        ),
        recurring: RecurringConfig(
            minOccurrencesDefault: 2,
            minOccurrencesByCadence: ["weekly": 5, "monthly": 3, "quarterly": 3, "yearly": 2],
            toleranceDaysByCadence: ["weekly": 2, "monthly": 5, "quarterly": 10, "yearly": 20],
            amountCVThreshold: 0.15
        ),
        insight: InsightConfig(
            spikeStdDevMultiplier: 2.0,
            anomalyStdDevMultiplier: 3.0,
            spikeMinimumRelativeIncrease: 0.20,
            spikeMinimumAbsoluteDeltaMinorUnits: 500_000,
            exposeConfidenceToUser: false
        ),
        graph: GraphConfig(
            edgeWeightIncrement: 0.1,
            edgeWeightMax: 10.0
        )
    )
}
```

Inject config into all intelligence components — never read globals from within service implementations.

### VPA gateway tokens → JSON

Create `FinanceIntelligence/Resources/merchant_gateways.json`:

```json
{
  "version": "2026-05-31.v1",
  "tokens": ["@rzp", "@ptys", "@ptybl", "bdsi@", "@okbizaxis"]
}
```

Replace static array in `UPIDescriptionParser.swift:merchantGatewayVPATokens` with injected `MerchantGatewayConfig`.

---

## 7. Observability

### `IntelligenceLogger`

```swift
protocol IntelligenceLogger {
    func record(_ event: IntelligenceEvent) async
}

struct IntelligenceEvent: Codable, Identifiable {
    let id: UUID
    let transactionId: String?
    let stage: IntelligenceStage
    let source: IntelligenceSource
    let ruleId: String?
    let modelId: String?
    let modelVersion: String?
    let configVersion: String?
    let outputLabel: String?
    let outputIntent: String?
    let confidence: Double?
    let confidenceKind: ConfidenceKind
    let debugJSON: String?
    let createdAt: Date
}

enum IntelligenceStage: String, Codable {
    case narrationParsing, merchantNormalization, featureExtraction
    case ruleCategorization, personalizedKNN, nlModelCategorization, finalCategorization
    case personResolution, graphBuild, recurringDetection, relationshipInference
    case descriptionGeneration, spendingInsight
}
```

**Log at every final decision point.** Do not store raw PII-heavy narrations. Store prefix, parser branch, or stable hash only.

### Debug export

`IntelligenceDebugExporter` should answer per import:
```
% by structural rule   % by personalized kNN   % by NLModel   % by fallback
average confidence by source     unparsed narration rate
merchant alias hit rate          person resolution rate
```

---

## 8. Confidence display policy

**Stop showing numeric confidence to users. It is uncalibrated.**

```swift
struct ConfidenceDisplayPolicy {
    func displayLabel(
        confidence: Double?,
        confidenceKind: ConfidenceKind,
        source: IntelligenceSource
    ) -> ConfidenceDisplay {
        switch confidenceKind {
        case .deterministic:      return .label("Matched rule")
        case .calibratedProbability: return calibratedLabel(confidence)
        case .uncalibratedScore, .heuristicOrdinal: return .label("Auto-categorized")
        case .notApplicable:      return .hidden
        }
    }
}
```

Acceptable user-facing labels:
- `Auto-categorized`
- `Learned from your corrections`
- `Matched a known bank pattern`
- `Needs review`

Never: `Confidence: 78%` or similar unless `confidenceKind == .calibratedProbability`.

---

## 9. kNN evaluation

### Stratified held-out split

```swift
func stratifiedSplit(
    examples: [TrainingExample],
    validationFraction: Double = 0.20,
    minValidationPerClass: Int = 1
) -> TrainValidationSplit
```

Rules:
- Categories with fewer than 5 examples: keep in training, mark coverage limitation
- Report global accuracy only when validation set has sufficient coverage
- Store category distribution in model metadata

### `ClassificationEvaluationResult`

```swift
struct ClassificationEvaluationResult: Codable {
    let exampleCount: Int
    let validationCount: Int
    let accuracy: Double
    let precisionMacro: Double
    let recallMacro: Double
    let f1Macro: Double
    let confusionMatrix: [String: [String: Int]]
    let coverage: Double
    let averageConfidence: Double?
}
```

**Never report training-set accuracy as held-out accuracy.** If validation set is too small: output `Insufficient validation data`.

---

## 10. Golden benchmark

### File location

```
Tests/Resources/golden_transactions.json
```

### Minimum coverage (50 examples)

| Group | Count |
|-------|------:|
| UPI merchant payments | 10 |
| UPI person transfers | 10 |
| Salary credits | 5 |
| Rent transfers | 5 |
| Card payments (CRED/BILLPAY/AmEx) | 5 |
| ATM withdrawals | 5 |
| SIP/NACH investments | 5 |
| Ambiguous narrations | 5 |

### Strict assertions (CI-blocking)
```
categoryId    intentId    isPersonTransfer    merchant/person classification
```

### Flexible (non-blocking)
```
confidence    description text    reason code wording
```

**Every new bank parser addition requires adding golden examples.**

---

## 11. Model registry

### Version naming

```
personalized-knn-YYYYMMDD-HHMMSS-<trainingDataHashPrefix>
coreml-category-v<bundleVersion>
```

### Invariants

- Every prediction carries `modelVersion`, `featureVersion`, `configVersion`
- Re-training creates a new metadata record — never overwrites
- Model write without metadata registration fails in debug builds
- Debug export shows current model version and validation metrics

---

## 12. Feedback loop

### Events to capture

| Signal | Event type | Priority |
|--------|-----------|----------|
| User category correction | `category_corrected` | P0 (exists) |
| User merchant correction | `merchant_corrected` | P0 |
| Relationship confirmed/rejected | `relationship_confirmed/rejected` | P1 |
| Insight opened/dismissed | `insight_opened/dismissed` | P2 |
| Recurring confirmed/rejected | `recurring_confirmed/rejected` | P2 |

### Privacy rule

Feedback events include:
- entity ID (not raw narration)
- old/new value
- model/config version at time of event
- event source

Do not train directly from weak implicit signals without review.

---

## 13. Data quality fixes

### Protect user-corrected merchants

```swift
// Only update merchantName if user has not manually corrected it
if !transaction.isUserCorrectedMerchant {
    updateMerchantNameFromIntelligence()
}
```

### Write `resolvedPersonId`

During person resolution, write `transaction.resolvedPersonId = resolvedEntities.personId`. Verify graph edge and transaction row agree.

### Fuzzy person deduplication

Conservative rules:
```
exact_match_auto_merge     (RITIK GUPTA vs Ritik Gupta)
strong_match_auto_merge    (edit distance ≤ 2 on canonical name)
possible_match_review      (partial name match)
```

Do not auto-merge aggressively. Log merge events.

### Name artifact sanitization

Detect and flag:
```
Repeated tokens (Manasa Manasa Sharm)
S/O D/O W/O suffixes (Lovish So Prem Kumar)
Gateway fragments in resolved names
Truncated suffix artifacts
```

Raw parsed value must remain available for audit.

---

## 14. Relationship inference hardening

### Immediate: reframe user-facing labels

Replace:
```
Landlord
Friend
Employer
```

With:
```
Likely landlord
Frequent transfer contact
Likely salary source
```

Until user confirms (`RelationshipVerificationState`):
```swift
enum RelationshipVerificationState: String, Codable {
    case inferred
    case userConfirmed
    case userRejected
    case userCorrected
}
```

### Keep these as deterministic exclusions

```
credit_card_payment → cannot be landlord
merchant_payment → cannot be family
salary_credit → cannot be friend payment
tax_payment → cannot be personal relationship
```

These are policy guards, not ML.

### Future ML replacement (S2)

Features for logistic regression / gradient-boosted classifier:
```
totalDebits/Credits    debitCreditRatio    averageDebitAmount
transactionCount       monthlyCadenceScore roundAmountRatio
postSalaryTimingRatio  rentKeywordSignal   recurringPatternSignal
timeSinceFirst/LastTransaction
```

Labels: `landlord`, `employer`, `family`, `friend`, `reimbursement`, `merchant`, `unknown`

**Do not replace rule baseline until held-out F1 macro exceeds it.**

---

## 15. Recurring detection hardening

### Move to config (immediate)

```
monthly ±5 days → RecurringConfig.toleranceDaysByCadence["monthly"]
weekly ±2 days  → RecurringConfig.toleranceDaysByCadence["weekly"]
min occurrences → RecurringConfig.minOccurrencesByCadence
```

### Strengthen min occurrences

```
weekly:    5+ occurrences
monthly:   3+ occurrences
quarterly: 3+ occurrences
yearly:    2+ occurrences
```

### Golden recurring dataset

```
Tests/Resources/golden_recurring_patterns.json
```

Include: monthly subscription, salary, rent, SIP, non-recurring repeated merchant, irregular, quarterly, annual.

### Future ML (S4)

Replace fixed tolerance windows with:
```
P(cadence | observed intervals)
```

Candidate: likelihood model over inter-transaction intervals per cadence, with amount consistency and merchant/category prior.

---

## 16. Spending insight hardening

### Replace fake confidence with evidence

```swift
// Before
confidence: 0.78

// After
InsightEvidence(
    baselineMean: ...,
    baselineStdDev: ...,
    observedValue: ...,
    absoluteDelta: ...,
    relativeDelta: ...,
    thresholdUsed: ...
)
```

### Add magnitude guards for spike detection

```
trigger only if:
monthlySpend > mean + k * stdDev
AND monthlySpend > mean * 1.20
AND monthlySpend - mean > ₹5,000
```

All three guards are configurable via `InsightConfig`.

---

## 17. Deprecating `LocalTransactionLearner`

1. Freeze writes — corrections route to `PersonalizedClassifier` only
2. Log both predictions in debug for one release to verify parity
3. Delete `Learning/LocalTransactionLearner.swift` after parity confirmed

---

## 18. Person-vs-merchant classifier (S1)

### Fast paths remain hardcoded
```
phone-number VPA prefix → person
known merchant gateway token → merchant
```

### Future `PersonMerchantClassifier`

Input: raw narration, VPA prefix/suffix, amount, direction  
Output: `{person, merchant, unknown}` with `confidenceKind: calibratedProbability`

**Do not replace `businessNameKeywords` until:**
```
person precision ≥ 95%
merchant precision ≥ 95%
held-out test includes multiple banks
fallback behavior defined
model version stored
```

Minimum labeled dataset: 5,000 narrations, balanced, multiple banks.

---

## 19. What must remain hardcoded

```
phone-number VPA structural detection      BILLPAY card-last4 extraction
UPI format prefix detection                amount math in minor units
date/currency normalization                database idempotency
foreign-key integrity                      user correction override
permission/security checks                 PII stripping before Apple Intelligence
audit logging                              schema validation
```

These are not ML problems.

---

## 20. Engineering tickets

### P0

| Ticket | Area | Implementation |
|--------|------|---------------|
| INTEL-001 | Observability | Add `intelligence_inference_events` table |
| INTEL-002 | Observability | Add `IntelligenceLogger` protocol + GRDB implementation |
| INTEL-003 | Classification | Add `source`, `confidenceKind`, `modelVersion`, `configVersion` to `CategoryPrediction` |
| INTEL-004 | UI/Trust | Add `ConfidenceDisplayPolicy`; suppress raw confidence in all user-facing UI |
| INTEL-005 | kNN | Add stratified held-out split; report validation accuracy only |
| INTEL-006 | Registry | Add `intelligence_model_metadata` table and `ModelRegistry` |
| INTEL-007 | Tests | Add 50-example golden transaction benchmark in CI |

### P1

| Ticket | Area | Implementation |
|--------|------|---------------|
| INTEL-008 | Config | Add `IntelligenceServiceConfiguration`; inject into all components |
| INTEL-009 | Parser | Move VPA gateway tokens to `merchant_gateways.json` |
| INTEL-010 | Rules | Add stable rule IDs; log `ruleId` in inference events |
| INTEL-011 | Relationships | Add `RelationshipDebugInfo`; emit evidence from `RelationshipEngine` |
| INTEL-012 | Recurring | Move cadence tolerances to `RecurringConfig` |
| INTEL-013 | Insights | Replace fake confidence with `InsightEvidence` |
| INTEL-014 | Graph | Move edge increment/cap to `GraphConfig` |

### P2

| Ticket | Area | Implementation |
|--------|------|---------------|
| INTEL-015 | Transactions | Add `lastEnrichedAt` column |
| INTEL-016 | Transactions | Write `resolvedPersonId` during person resolution |
| INTEL-017 | Corrections | Add `isUserCorrectedMerchant`; protect from reprocessing |
| INTEL-018 | Feedback | Add `FeedbackStore` + `intelligence_feedback_events` table |
| INTEL-019 | People | Add fuzzy dedup candidate detection |
| INTEL-020 | Learning | Deprecate `LocalTransactionLearner` |

### Strategic ML

| Ticket | Area | Implementation |
|--------|------|---------------|
| ML-001 | Labels | Build person/merchant labeled dataset (5,000+ narrations) |
| ML-002 | Model | Train `PersonMerchantClassifier`; beats keyword baseline on held-out |
| ML-003 | Labels | Collect relationship confirmations/rejections via `FeedbackStore` |
| ML-004 | Model | Train relationship classifier; beats rule baseline; calibrated probabilities |
| ML-005 | Insights | Add personalized anomaly baseline; lower dismissal rate than 2σ |
| ML-006 | Recurring | Add probabilistic cadence scoring; higher precision than tolerance windows |

---

## 21. Acceptance metrics

### Categorization
```
golden benchmark accuracy ≥ 95%
held-out accuracy reported for every trained model
fallback rate does not increase after config refactor
user correction rate tracked per model version
```

### Parser
```
known HDFC golden examples pass
unknown prefixes logged, not silently swallowed
unparsed narration rate < 1% on HDFC statements
```

### Relationships
```
100% of inferred relationships have debug evidence
no relationship with confidenceKind=heuristicOrdinal displayed as certain
confirmation/rejection tracked via FeedbackStore
```

### Recurring
```
golden recurring benchmark passes
patterns with only 2 occurrences marked low-evidence
cadence labels carry toleranceDays in debug output
```

### Insights
```
no user-visible fake confidence
every insight includes InsightEvidence
spike alerts require statistical AND practical magnitude
dismissal rate tracked by insight type
```

### Model quality
```
no model promoted without metadata
no model replaces rule baseline without held-out comparison
Brier score computed for any model with calibration claim
```

---

## 22. Recommended implementation order

Implement in this exact order:

```
1.  Add inference event schema + IntelligenceLogger
2.  Add source/confidenceKind/modelVersion/configVersion to predictions
3.  Suppress raw confidence in user-facing UI
4.  Add kNN held-out evaluation
5.  Add ModelRegistry; persist model metadata
6.  Add golden transaction benchmark
7.  Extract thresholds into IntelligenceServiceConfiguration
8.  Move VPA gateway tokens to JSON config
9.  Add relationship and recurring debug info
10. Add FeedbackStore
11. Add transaction enrichment provenance fields
12. Protect user-corrected merchant names
13. Write resolvedPersonId
14. Deprecate LocalTransactionLearner
15. Add fuzzy person deduplication
16. Begin person-vs-merchant labeled dataset
17. Train and evaluate PersonMerchantClassifier
18. Begin relationship label collection
19. Replace relationship additive scoring only after baseline is beaten
20. Add personalized insight and recurring ML models after feedback volume exists
```

---

## 23. Definition of done

The intelligence pipeline is production-auditable when:

```
✓ Every prediction has source provenance
✓ Every model prediction has model version
✓ Every threshold comes from named config
✓ Every user-facing intelligence output has explanation or evidence
✓ Every user correction is stored as feedback
✓ Every model has held-out evaluation metadata
✓ Every parser/category change runs against golden tests
✓ Every uncalibrated confidence is hidden or clearly marked internal-only
✓ Every relationship inference has reason codes
✓ Every recurring pattern has cadence evidence
✓ Every re-enrichment preserves user corrections
```
