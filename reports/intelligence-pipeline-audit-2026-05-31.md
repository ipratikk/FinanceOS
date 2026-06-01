# FinanceOS Intelligence Pipeline — Technical Audit Report

**Date:** 2026-05-31  
**Auditor:** Claude Sonnet 4.6 (ML Systems Audit)  
**Scope:** Full FinanceIntelligence package + app-layer intelligence integration  
**Branch:** feat/financial-intelligence-platform

---

## Executive Summary

FinanceOS has a layered intelligence pipeline with genuine architectural thinking — it correctly separates categorization, entity resolution, relationship inference, and recurring detection into distinct stages. The system uses a defensible hybrid approach: deterministic parsing → on-device kNN (MLUpdateTask) → NLModel fallback → rule fallback. The major refactoring done this session (pruning keyword rules, training the kNN on 685 examples) moves the system in the right direction.

However, significant risks remain. The pipeline has **no evaluation harness, no regression tests, no monitoring, no model versioning, and no offline benchmark dataset**. Every model decision produces a confidence score that is neither calibrated nor logged in a way that can be analyzed post-hoc. The relationship classifier is a fully hardcoded decision tree masquerading as inference. The recurring detector uses hardcoded tolerance bounds that will fail on atypical cadences. The insight engine uses 2σ and 3σ thresholds that are mathematically valid but uncalibrated to this user's actual distribution.

The system is sound enough for a personal finance app at early stage. It would not survive a fintech production audit without significant investment in observability, evaluation, and separation of concerns.

---

## Intelligence Pipeline Map

| Stage | Input | Output | Current Logic | Owner File | Risk Level | Notes |
|-------|-------|--------|---------------|------------|------------|-------|
| **Raw ingestion** | CSV/XLSX bank statement | `Transaction` rows | Parser rules (bank-specific) | `FinanceParsers/` | Medium | Parser is bank-specific brittle regex; HDFC-only tested |
| **Narration parsing** | Raw bank narration string | Merchant segment, VPA, isPersonTransfer flag | Prefix-based format detection (`UPI-`, `NEFT CR-`, `IMPS-`, `UPI/`, `UPL/`) | `Features/UPIDescriptionParser.swift` | Medium | Brittle to undiscovered prefixes; no fallback telemetry |
| **Merchant normalization** | Parsed merchant segment | `MerchantCandidate` (canonical name, category hint, confidence) | Alias table → fuzzy match → title-case fallback | `MerchantNormalization/MerchantNormalizer.swift` | Medium | Alias table is static JSON; no update mechanism |
| **Feature extraction** | `Transaction` + `MerchantCandidate` | `TransactionFeatures` (20-dim binary indicators) | Boolean heuristics on normalized description | `Features/TransactionFeatureExtractor.swift` | Medium | 200-dim bag-of-words vocabulary is HDFC-specific; no validation |
| **Rule engine** | `TransactionFeatures` | `CategoryPrediction` + `IntentPrediction` (if conf ≥ 0.92) | Priority-ordered deterministic rules | `RuleEngine/BuiltInRules.swift` | Low | Correctly pruned to structural rules only post-training |
| **Category classification (kNN)** | `TransactionFeatures` | `CategoryPrediction` (conf ≥ 0.70) | MLUpdateTask kNN, 200-dim BoW | `Learning/PersonalizedClassifier.swift` | Medium | 99% accuracy on training set; no held-out evaluation |
| **Category classification (NLModel)** | Normalized description text | `CategoryPrediction` | CreateML NLModel text classifier | `Categorization/CoreMLCategorizer.swift` | Low | Model version not stored per-prediction; no regression tests |
| **Legacy kNN** | Normalized description BoW | `CategoryPrediction` | Swift-native kNN (LocalTransactionLearner) | `Learning/LocalTransactionLearner.swift` | Low | Redundant with PersonalizedClassifier; both fire on corrections |
| **Person resolution** | Raw narration string | `ResolvedEntities` (personId?) | UPI VPA type detection (phone-number prefix, gateway tokens, business keywords) | `EntityResolution/PersonResolver.swift` | Medium | Business keyword list still partially hardcoded in `UPIDescriptionParser` |
| **Person persistence** | `ResolvedEntities` | `Person` row in SQLite | GRDB upsert; alias deduplication by normalized name | `Persistence/GRDBIntelligencePersonRepository.swift` | Low | Alias merge is deterministic; correct |
| **Knowledge graph build** | `EnrichedTransaction[]` | `GraphNode[]`, `GraphEdge[]` | Deterministic: node-per-entity, edge-per-transaction | `KnowledgeGraph/GraphBuilder.swift` | Low | Edge weight increment is Bayesian-style; no calibration |
| **Recurring detection** | `DetectionInput[]` grouped by merchantKey | `RecurringPattern[]` | Interval clustering per cadence with tolerance bounds | `Recurring/RecurringDetector.swift` + `PatternAnalyzer.swift` | High | All tolerance bounds and min-occurrence thresholds hardcoded |
| **Relationship inference** | Person transaction history + salary dates | `Relationship` (type + confidence) | Hardcoded scoring function with additive confidence weights | `Relationships/RelationshipEngine.swift` + `RelationshipClassifier.swift` | High | Fully deterministic decision tree; not a real classifier |
| **Description generation** | `DescriptionContext` (merchant, intent, isDebit) | Human-readable sentence | Template + Apple Intelligence (if available) | `DescriptionGeneration/DescriptionGenerator.swift` | Low | Templates are reasonable; Apple Intelligence path unaudited |
| **Spending insights** | `[Transaction]` raw | `[TransactionInsight]` | Hardcoded 2σ spike detector, 3σ anomaly detector, interval clustering | `Insights/SpendingInsightEngine.swift` | Medium | Thresholds uncalibrated; no personalization |
| **User correction** | User-selected category override | Stored correction + kNN update via MLUpdateTask | Two-store write: correction log + kNN model update | `Corrections/UserCorrectionStore.swift` + `Learning/PersonalizedClassifier.swift` | Low | Architecture correct; no deduplication of corrections |
| **Export/training data** | All categorized transactions | `training-category.json` | Snapshot export | `IntelligenceExporter.swift` | Low | One-shot; no versioning or lineage tracking |

---

## Hardcoded Rule Inventory

| Rule / Heuristic | Location | Purpose | Current Behavior | Risk | Recommendation | Rationale |
|-----------------|----------|---------|-----------------|------|----------------|-----------|
| VPA merchant gateway token list (`@rzp`, `@ptys`, `@ptybl`, `bdsi@`, `@okbizaxis`) | `UPIDescriptionParser.swift:27-35` | Distinguish merchant vs person UPI | Exact string token match in VPA suffix | Medium | **B — Configuration** | These expand as new payment gateways launch. Should be a DB-backed or remote config list, not Swift source. |
| Business name keywords (`traders`, `pvt`, `ltd`, `bbnow`, `dominos`, etc.) | `UPIDescriptionParser.swift:38-55` | Prevent merchant names from resolving as persons | Substring match against 40+ keywords | High | **E — Hybrid: keep short structural list + ML classifier** | Merchant vs person disambiguation is a classification problem. The keyword list is HDFC-specific and will miss new merchants. Pair with a trained binary classifier (person/merchant NLModel). |
| Phone-number VPA prefix detection (10-digit / 12-digit with 91 prefix) | `UPIDescriptionParser.swift:136-138` | Always classify numeric VPA prefix as person | Hardcoded digit count check | Low | **A — Keep hardcoded** | This is a structural invariant of Indian UPI: phone numbers ARE personal VPAs. |
| `parseIMPS` always person-transfer | `UPIDescriptionParser.swift:145-156` | IMPS format → person | After fix: runs `isMerchantPayment`; previously always false | Low | **A — Keep hardcoded** | IMPS is always P2P; the merchant check is correct guard. |
| BILLPAY regex `X{4,}(\d{4})` | `MerchantNormalizer.swift:parseBillPay` | Extract card last-4 from IB BILLPAY narration | Regex on masked card number | Low | **A — Keep hardcoded** | This is format-parsing, not classification. Structurally stable. |
| Rule threshold 0.92 in `analyzeEnriched` | `TransactionIntelligenceServiceImpl.swift:169` | Only high-confidence structural rules override kNN | Magic number | Medium | **B — Configuration** | This threshold is the key lever between rules and ML. Should be a named constant or config value, not an inline literal. |
| kNN confidence threshold 0.70 | `PersonalizedClassifier.swift:27` | kNN must exceed this to be used | Static constant | Medium | **B — Configuration** | This threshold calibrates ML/rule boundary. Should be tunable without a code deploy, ideally via A/B experiment. |
| Landlord confidence weights (0.55 base, +0.10, +0.08, +0.10, +0.07, +0.05) | `RelationshipClassifier.swift:landlordConfidence()` | Score landlord relationship | Additive score with fixed weights | High | **D — ML model** | These weights are invented, not calibrated. A gradient-boosted classifier over signals would produce calibrated probabilities. |
| Employer classification (`totalCredits > totalDebits * 3`) | `RelationshipClassifier.swift:classify()` | Detect employer relationship | Hardcoded 3× multiplier | High | **D — ML model** | Magic number. Fails if employer also receives reimbursements. No training data currently exists to validate this ratio. |
| Family threshold (`averageDebitAmount > 500_000`) | `RelationshipClassifier.swift:classify()` | Classify family based on large transfers | ₹5,000 threshold | High | **D — ML model** | No signal justification. Many landlords and high-value friends will exceed this. |
| Minimum evidence threshold (`confidence >= 0.40`) | `RelationshipEngine.swift:inferRelationship()` | Filter weak relationship inferences | Hardcoded confidence cutoff | Medium | **B — Configuration** | This controls relationship recall. Should be a configurable threshold with documented business rationale. |
| Rent keywords (`rent`, `owner`, `landlord`, `sir`, `maam`, `aunty`, `uncle`) | `RelationshipEngine.swift:rentKeywords` | Detect rent-related UPI labels | Static keyword list | High | **D — ML model** | These are English/Indian cultural terms. Misses Hindi, Tamil, Kannada variants. Should be an embedding-based match or ML signal. |
| Round-amount threshold (`amount % 50000 == 0`) | `RelationshipEngine.swift:isRoundAmount()` | Signal for landlord/regular payments | Divisible by ₹500 exactly | Medium | **B — Configuration** | The ₹500 unit is plausible but arbitrary. Should be config. Fails for odd rent amounts like ₹22,500. |
| Post-salary timing window (≤ 7 days) | `RelationshipEngine.swift:hasPostSalaryTiming()` | Signal: payment made within a week of salary | Hardcoded 7-day window | Medium | **B — Configuration** | Business-tunable. Some people pay rent on the 1st regardless of salary date. Should be configurable. |
| Recurring interval tolerance (monthly: ±5 days, weekly: ±2, quarterly: ±10) | `Recurring/PatternAnalyzer.swift` | Decide if transaction interval matches a cadence | Static tolerance per cadence | High | **E — Hybrid** | Tolerances are correct for standard cadences but fail for irregular billing (e.g., 28/29/30/31-day months). Replace with a probabilistic cadence model. |
| Min occurrences for recurring detection (≥ 2) | `RecurringDetector.swift:detect()` | Require at least 2 transactions | Magic number | Medium | **B — Configuration** | 2 is too few for high-confidence detection. Should be configurable per cadence (monthly needs 3+, weekly 5+). |
| Spending spike threshold: 2σ | `SpendingInsightEngine.swift:detectSpikes()` | Alert when monthly spend > mean + 2σ | Population-level statistical threshold | Medium | **E — Hybrid** | 2σ is reasonable statistically but not calibrated to alert precision. Should add a minimum absolute magnitude guard (e.g., 20% above mean AND > ₹5,000 delta). |
| Unusually large transaction: 3σ | `SpendingInsightEngine.swift:detectUnusuallyLarge()` | Flag individual large transactions | Population-level threshold | Medium | **E — Hybrid** | Same problem. Should be user-calibrated (users with volatile income will have high σ naturally). |
| CV < 0.15 for subscription detection | `SpendingInsightEngine.swift:evaluateIntervals()` | Amount consistency signals subscription | Hardcoded coefficient of variation | Medium | **B — Configuration** | 0.15 is reasonable but undocumented. Should be a named constant. |
| Confidence values in insight generation (0.85, 0.80, 0.78, 0.75) | `SpendingInsightEngine.swift` | User-facing confidence on insights | Arbitrary constants | High | **F — Remove or calibrate** | These confidence values are completely uncalibrated. Do not expose them to users unless they have been empirically validated. They create false precision. |
| Graph edge weight increment (+0.1, max 10.0) | `GRDBGraphRepository.swift:upsertEdge()` | Bayesian-style confidence accumulation | Hardcoded increment | Low | **B — Configuration** | The 0.1 increment and 10.0 cap are not derived from any model. Should be named constants and documented. |
| `fromPersonId` always nil in relationships | `PostProcessingPipeline.swift:inferRelationships()` | The "self" entity has no person record | Structural gap | Medium | **C — Policy layer** | The user (account owner) should be a first-class entity in the graph. This is a schema design gap, not a rule. |

---

## Keep Hardcoded

| Logic | Location | Why It Should Stay Deterministic | Required Tests | Required Observability |
|-------|----------|----------------------------------|----------------|------------------------|
| Phone-number VPA → person | `UPIDescriptionParser.swift:136-138` | Structural invariant of Indian UPI specification | Unit test: 10-digit numeric prefix → person, 12-digit 91-prefix → person, alpha prefix → not-person | Log when this path fires per transaction |
| BILLPAY card-last4 extraction | `MerchantNormalizer.swift:parseBillPay()` | Format parsing — not classification | Unit test: `IB BILLPAY DR-HDFCWI-552260XXXXXX9081` → `Card Payment ••••9081` | Log extraction success/failure rate |
| `UPI/` and `UPL/` slash-format parsing | `UPIDescriptionParser.swift:parseUPISlash()` | HDFC structural format | Unit test each prefix variant | Log which prefix fired |
| Amount in minor units (paise) | `Transaction.amountMinorUnits` | Financial math — must be exact | Property test: no floating point operations on amounts | N/A |
| Graph FK cascade delete | `AppMigration.swift:v13` | Data integrity | Integration test | DB error logging |
| Dedup logic in recurring pattern save | `GRDBRecurringPatternRepository.swift:save()` | Idempotency — prevents duplicate patterns on re-run | Unit test: calling save() twice produces one row | Log upsert vs insert count |
| Dedup logic in relationship save | `GRDBRelationshipRepository.swift:save()` | Idempotency | Unit test: calling save() twice produces one row | Log upsert vs insert count |
| User correction storage | `UserCorrectionStore.swift` | Feedback audit trail — must be lossless | Test: correction survives app restart | Log correction events with transactionId |

---

## Move to Configuration

| Logic | Location | Proposed Config Mechanism | Owner | Approval Needed | Versioning Needed |
|-------|----------|--------------------------|-------|----------------|-------------------|
| VPA merchant gateway tokens (`@rzp`, `@ptys`, etc.) | `UPIDescriptionParser.swift:merchantGatewayVPATokens` | Bundled `merchant_gateways.json`, hot-reloadable | ML/Data team | No (additive) | Yes — new tokens affect person resolution retroactively |
| Rule engine confidence threshold (0.92) | `TransactionIntelligenceServiceImpl.swift:169` | Named constant → `IntelligenceServiceConfiguration.ruleConfidenceThreshold` | Engineering | Yes | Yes |
| kNN confidence threshold (0.70) | `PersonalizedClassifier.swift:27` | `IntelligenceServiceConfiguration.knnConfidenceThreshold` | Engineering | Yes | Yes |
| Relationship confidence cutoff (0.40) | `RelationshipEngine.swift:inferRelationship()` | `IntelligenceServiceConfiguration.relationshipMinConfidence` | Product | Yes | Yes |
| Post-salary timing window (7 days) | `RelationshipEngine.swift:hasPostSalaryTiming()` | `RelationshipConfig.postSalaryWindowDays: Int` | Product | No | Yes |
| Round-amount divisor (₹500 = 50000 minor units) | `RelationshipEngine.swift:isRoundAmount()` | `RelationshipConfig.roundAmountGranularity: Int64` | Product | No | Yes |
| Min occurrences for recurring (2) | `RecurringDetector.swift:detect()` | `RecurringConfig.minOccurrences: Int` | Product | No | Yes |
| Subscription CV threshold (0.15) | `SpendingInsightEngine.swift` | `InsightConfig.subscriptionAmountCV: Double` | Product | No | Yes |
| Spending spike multiplier (2σ) | `SpendingInsightEngine.swift:detectSpikes()` | `InsightConfig.spikeStdDevMultiplier: Double` | Product | No | Yes |
| Anomaly threshold (3σ) | `SpendingInsightEngine.swift:detectUnusuallyLarge()` | `InsightConfig.anomalyStdDevMultiplier: Double` | Product | No | Yes |
| Graph edge weight increment (0.1) | `GRDBGraphRepository.swift:upsertEdge()` | `GraphConfig.edgeWeightIncrement: Double` | Engineering | No | No |
| Graph edge weight cap (10.0) | `GRDBGraphRepository.swift:upsertEdge()` | `GraphConfig.edgeWeightMax: Double` | Engineering | No | No |

---

## Move to ML

| Current Rule | Location | Proposed ML Approach | Labels Needed | Features Needed | Metrics | Fallback | Migration Complexity | Business Impact |
|-------------|----------|---------------------|---------------|-----------------|---------|----------|---------------------|-----------------|
| Merchant vs person binary classification (businessNameKeywords list) | `UPIDescriptionParser.swift:businessNameKeywords` | Binary NLModel text classifier trained on narrations. Input: narration string. Output: {person, merchant} with confidence | 5k+ labeled narrations (person/merchant ground truth) | Full raw narration text | Precision/recall at 0.95+ on held-out set; false positive rate on person transactions | Keep keyword list as high-confidence fast-path | Medium — requires labeled data collection from existing transactions | High — reduces false-positive person resolution significantly across new banks |
| Relationship classification (landlord / friend / employer / family / reimbursement) | `RelationshipClassifier.swift` | Gradient-boosted classifier (e.g., XGBoost) or logistic regression over behavioral signals | 500+ labeled (personId, relationshipType) pairs — requires user validation | totalDebits, totalCredits, avgAmount, transactionCount, cadence, postSalaryDelta, roundAmountRatio, upiLabelMatch, occurrenceCount | Precision/recall per class, confusion matrix, F1 macro | Current rule-based classifier as fallback | High — requires labeled data collection | High — relationship labels drive trust in financial insights |
| Landlord confidence scoring (additive weights) | `RelationshipClassifier.swift:landlordConfidence()` | Logistic regression calibrated probabilities | Same as above | Signal binary features (has_round_number, post_salary, upi_label, monthly_cadence, occurrence_count) | Calibration curve, Brier score | Current additive weights | Low — drop-in replacement once labels exist | Medium — confidence calibration affects user trust |
| Spending spike threshold (2σ) | `SpendingInsightEngine.swift:detectSpikes()` | Personalized anomaly detection (user-specific Z-score baseline with exponential smoothing) | Implicit: user dismissal / engagement with insight | Monthly spend by category, month index, income variability | Alert precision rate (user engagement vs dismissal ratio) | Current population-level 2σ | Low | Medium — reduces alert fatigue |
| Unusually large transaction (3σ) | `SpendingInsightEngine.swift:detectUnusuallyLarge()` | Isolation Forest or percentile-based per-user baseline | Same implicit signals | Transaction amount, merchant category, time-of-month | False positive rate, user correction rate | Current 3σ | Low | Medium |
| Recurring pattern cadence detection | `Recurring/PatternAnalyzer.swift` | Hidden Markov Model or probabilistic cadence inference over date sequences | Implicit: user confirmations of recurring patterns | Sequence of inter-transaction intervals per merchant | Cadence precision, false-positive recurring rate | Current tolerance-window approach | Medium | High — recurring detection drives subscription awareness |

---

## Hybrid Rule + ML Candidates

| Use Case | Deterministic Layer | ML Layer | Confidence Handling | Fallback | Explanation Strategy |
|----------|--------------------|----|--------------------|----|----------------------|
| Person vs merchant classification | VPA gateway tokens (exact match → merchant), phone prefix (exact match → person) | Binary NLModel on narration text for ambiguous cases | Structural rules fire at 1.0; NLModel confidence threshold 0.80 | Default to merchant for non-UPI narrations | Show VPA token or model prediction |
| Transaction categorization | Structural rules (salary/ATM/SIP format) at 0.92+ | kNN (PersonalizedClassifier) → NLModel text classifier | Rule wins if conf ≥ 0.92; kNN wins if conf ≥ 0.70; NLModel otherwise | Last rule in `catchAllRules` | Show source: "Auto-categorized by rule" vs "Auto-categorized by model" |
| Relationship type inference | Minimum evidence guards (≥ 2 txns, dominantIntent exclusions) | Logistic regression over behavioral signals | Hard gates (credit_card_payment excluded from landlord) stay deterministic | `.unknown` relationship type | Show contributing signals as reason codes |
| Recurring detection | Format-based cadence (SIP `nach debit` → monthly) | Probabilistic interval model for non-structural patterns | Rule cadence at 1.0; model cadence with calibrated confidence | Skip pattern if confidence < 0.50 | "Detected from N transactions over M months" |

---

## LLM / Prompt Audit

| Prompt / LLM Flow | Location | Purpose | Risk | Issues | Recommendation | Required Evaluation |
|-------------------|----------|---------|------|--------|----------------|---------------------|
| Apple Intelligence adapter | `DescriptionGeneration/AppleIntelligenceAdapter.swift` | Generate human-readable transaction descriptions | Low | Unknown: if it calls Apple Intelligence with financial data, PII controls must be verified | **F — Needs stronger guardrails**: verify PII stripping before Apple Intelligence call; ensure narration stripped of account numbers, VPAs, transaction IDs | PII leakage test; output consistency test; fallback rate monitoring |
| Fallback description generator | `DescriptionGeneration/FallbackGenerator.swift` | Template-based descriptions when LLM unavailable | None | Templates are correct for simple cases | **A — Good use case** | Template coverage test across all intent types |

No direct LLM calls to external APIs were found. Apple Intelligence path is the only probabilistic text generation. This is appropriate risk level for a local app.

---

## Scoring and Ranking Audit

| Score / Ranker | Location | Inputs | Current Method | Issues | Recommended Method | Metrics |
|---------------|----------|--------|---------------|--------|-------------------|---------|
| Category prediction confidence | `CategoryPrediction.confidence` | Model output or rule confidence | Raw model probability / rule-assigned constant | Rule-assigned constants (0.92, 0.88, etc.) are not calibrated probabilities | Platt scaling on kNN output; temperature scaling on NLModel | Brier score, ECE (expected calibration error) |
| Relationship confidence | `RelationshipClassifier.classify()` | Behavioral signals | Additive scoring (base 0.55 + signal increments) | Uncalibrated; values are invented | Logistic regression; calibration curve against ground truth | Calibration curve; precision at conf ≥ 0.70 |
| Recurring pattern confidence | `RecurringDetector` | Interval consistency, occurrence count | Heuristic from PatternAnalyzer | Not publicly documented | Likelihood ratio of observed intervals under each cadence hypothesis | Precision of cadence label vs ground truth |
| Insight severity (`.info`, `.warning`, `.alert`) | `SpendingInsightEngine.swift` | Spike/anomaly magnitude | Hardcoded per insight type | No severity calibration; alert fatigue risk | Severity should scale with magnitude and personalized baseline | Alert acceptance rate; user correction rate |
| Graph edge weight | `GRDBGraphRepository.upsertEdge()` | Observation count | `weight += 0.1`, `max 10.0` | Arbitrary increment; no normalization | PageRank-style or decayed observation count | No ranking currently surfaced to user |

**Verdict on all scoring systems:** None are calibrated. All confidence scores currently reaching the user or influencing ML decisions should be treated as uncalibrated ordinal values, not probabilities. The minimum viable fix is to label these explicitly in the codebase with `// UNCALIBRATED — ordinal ranking only`.

---

## Data and Feature Quality Issues

| Issue | Affected Component | Impact | Detection Method | Recommended Fix |
|-------|-------------------|--------|-----------------|-----------------|
| kNN trained on training set (no held-out split) | `PersonalizedClassifier` | 99% accuracy is overfitted to seen transactions; real accuracy on new bank unknown | Export test split; re-evaluate | Always hold out 20% of each import batch as test before training; report test accuracy in UI |
| 200-dim vocabulary is HDFC-specific | `PersonalizedClassifier` + `LocalTransactionLearner` | Coverage will drop significantly on ICICI/Axis narrations | Monitor coverage metric across imports | Expand vocabulary as new banks are added; or use NLModel (character-level) instead of BoW |
| `merchantName` on `Transaction` is mutable through corrections | `GRDBTransactionRepository.updateIntelligence()` | Re-processing the same transaction may overwrite a user-corrected merchantName | Log before/after on every update | Only update merchantName if user has not manually corrected it (add `isUserCorrectedMerchant` flag) |
| `resolvedPersonId` column exists in schema but is never written | `Transaction` model (v10 migration) | Dead schema column; person→transaction link lives only in graph | Grep for writes | Either write it during categorization (simplifies person lookup) or remove the column |
| No timestamp on when a transaction was last enriched | `Transaction` model | Cannot detect stale enrichment or re-run enrichment selectively | N/A | Add `lastEnrichedAt: Date?` column |
| Person name deduplication relies on exact normalized name match | `GRDBIntelligencePersonRepository` | "RITIK GUPTA" vs "Ritik Gupta" vs "RITIK KUMAR GUPTA" produce separate persons | Compare persons table after import | Fuzzy name deduplication (edit distance or embedding similarity) as pre-merge step |
| Name artifacts (`Manasa Manasa Sharm`, `Lovish So Prem Kumar`) | `UPIDescriptionParser` → `PersonResolver` | Corrupted canonical names stored in persons table | Inspect persons export | Post-processing: flag canonical names with repeated tokens or known artifacts (S/O, D/O) for review |
| Training data export is not versioned | `IntelligenceExporter.writeMLTrainingData()` | Cannot reproduce which examples trained which model version | N/A | Embed `exportedAt`, `transactionCount`, `categoryDistribution` in training JSON; store alongside model |
| kNN vocabulary shared between PersonalizedClassifier and LocalTransactionLearner | `Learning/BundledSeeds.swift` | Two separate kNN models trained on same BoW features — redundant | N/A | Deprecate `LocalTransactionLearner`; consolidate to `PersonalizedClassifier` |

---

## Observability and Evaluation Gaps

| Component | Missing Evaluation | Missing Monitoring | Risk | Recommended Fix |
|-----------|-------------------|-------------------|------|-----------------|
| **TransactionIntelligenceServiceImpl** | No offline benchmark; no held-out test set; no regression tests | No logging of which path fired (rule/kNN/NLModel) per transaction | High | Log `{transactionId, source, categoryId, confidence}` per inference; build golden test file from 50 hand-labeled transactions |
| **PersonalizedClassifier** | Evaluation runs on training data only (overfitting risk) | No coverage metric logged; no confidence distribution tracked | High | Reserve 20% of each training batch as test set; log `{coverage, accuracy, avgConfidence}` after each training run to persistent file |
| **RelationshipClassifier** | No evaluation dataset; no ground truth | No logging of which signals fired | High | Add `RelationshipDebugInfo` struct; log signal bitmap per inference |
| **RecurringDetector** | No precision measurement on detected patterns | No logging of false positive rate | Medium | Build golden dataset: 20 merchants known to be recurring, 20 known non-recurring; compute precision/recall |
| **SpendingInsightEngine** | No alert precision measurement | No dismissal/acceptance tracking | Medium | Log insight delivery + user action (dismissed / tapped / ignored) |
| **CoreMLCategorizer (NLModel)** | No test results stored; no regression suite | Model version not logged per prediction | Medium | Store `nlModelVersion` string in `CategoryPrediction`; run 50-example regression test on each model reload |
| **UPIDescriptionParser** | No coverage of edge cases across banks | No logging of failed parse attempts | Medium | Log `{narration_prefix, parseResult}` for first 100 chars; monitor "unparsed" rate |
| **MerchantNormalizer** | No evaluation of canonical name quality | No fallback rate logging | Low | Log when falling back to raw title-case; track alias hit rate |

---

## Architecture Recommendations

### Target Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  DETERMINISTIC POLICY LAYER (always runs, always correct)   │
│  - Amount normalization (paise)                             │
│  - UPI format parsing (structural prefixes)                 │
│  - Structural rules (salary, ATM, SIP format, SGST)         │
│  - Business name gateway token check                        │
│  - User correction override                                 │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────┐
│  CONFIGURABLE RULES LAYER (tuned by product, not ML)        │
│  - Confidence thresholds (knnThreshold, ruleThreshold)      │
│  - Timing windows (postSalaryDays)                          │
│  - Alert magnitude thresholds (spikeMultiplier)             │
│  - Merchant gateway token list (remote config)              │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────┐
│  ML INFERENCE LAYER                                         │
│  - PersonalizedClassifier (kNN, MLUpdateTask)               │
│  - CoreMLCategorizer (NLModel, text classifier)             │
│  - [Future] Person/merchant binary classifier               │
│  - [Future] Relationship logistic regression                │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────┐
│  POST-PROCESSING + GRAPH LAYER                              │
│  - Knowledge graph build (deterministic)                    │
│  - Recurring pattern detection (hybrid)                     │
│  - Relationship inference (hybrid → ML)                     │
│  - Description generation (template + Apple Intelligence)   │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────┐
│  FEEDBACK + EVALUATION LAYER (currently missing)            │
│  - User correction log (exists)                             │
│  - Insight engagement tracking (missing)                    │
│  - Model version per prediction (missing)                   │
│  - Held-out evaluation benchmark (missing)                  │
│  - Regression test suite (missing)                          │
└─────────────────────────────────────────────────────────────┘
```

### Missing Infrastructure

1. **`IntelligenceLogger`** — structured log of every inference decision with source, confidence, modelVersion
2. **`EvaluationHarness`** — 50-100 hand-labeled golden transactions; run after each model update
3. **`ModelRegistry`** — store modelVersion, trainedAt, exampleCount, evalAccuracy alongside each `PersonalizedKNN.mlmodelc` write
4. **`FeedbackStore`** — insight dismissal/acceptance events linked to insight ID
5. **`ConfigurationService`** — runtime-tunable thresholds, separate from code

---

## Priority Roadmap

### Immediate Fixes
*Issues that create correctness, compliance, or trust risk.*

| Priority | Recommendation | Why Now | Effort | Risk Reduction | Expected Impact |
|----------|---------------|---------|--------|----------------|-----------------|
| P0 | Remove or suppress uncalibrated confidence scores from user-facing UI | Showing `confidence: 0.78` to users implies precision the system doesn't have | 1 day | High | Immediate trust improvement |
| P0 | Add held-out test split before kNN training; report test accuracy not training accuracy | The reported 99% is on training data and is meaningless | 2 days | High | Real accuracy signal |
| P0 | Log inference source per transaction (`rule`, `knn`, `nlmodel`, `fallback`) | Regressions invisible without this | 1 day | High | Enables regression detection |
| P1 | Extract all magic numbers to named constants or `IntelligenceServiceConfiguration` | 0.92, 0.70, 0.40, 7 days, 50000, 0.15, 2σ, 3σ are all inline literals | 1 day | Medium | Eliminates silent tuning risk |
| P1 | Move VPA merchant gateway token list to bundled JSON config | Next payment gateway will require code deploy | 2 days | Medium | Removes code deploy requirement for data changes |

### Near-Term Improvements
*Changes that improve maintainability, evaluation, and observability.*

| Priority | Recommendation | Why Now | Effort | Risk Reduction | Expected Impact |
|----------|---------------|---------|--------|----------------|-----------------|
| P2 | Build 50-example golden transaction benchmark; run after every model update | Foundation for all future evaluation | 1 week | High | Regression safety net |
| P2 | Add `RelationshipDebugInfo` struct logging which signals fired per relationship | Blindly showing relationship labels without rationale | 2 days | Medium | Debuggability + user explanation |
| P2 | Deprecate `LocalTransactionLearner`; route all corrections to `PersonalizedClassifier` only | Dual learning creates divergence risk | 1 day | Low | Simplification |
| P2 | Write `resolvedPersonId` to `Transaction` during categorization | Dead schema column wastes migration complexity | 1 day | Low | Enables simpler person lookups in UI |
| P2 | Store model metadata (version, trainedAt, exampleCount, evalAccuracy) in `intelligence_model_metadata` table after each training run | No model provenance currently | 1 day | Medium | Audit trail |
| P3 | Add insight dismissal/acceptance tracking to `FeedbackStore` | Needed for any future insight quality improvement | 3 days | Medium | Feedback loop foundation |
| P3 | Add fuzzy name deduplication in `PersonResolver` (edit distance ≤ 2 on canonical names) | `RITIK GUPTA` and `RITIK KUMAR GUPTA` stored as separate persons | 3 days | Medium | Improves person resolution quality |

### Strategic ML Investments
*Larger modeling work to replace brittle heuristics.*

| Priority | Recommendation | Why Now | Effort | Risk Reduction | Expected Impact |
|----------|---------------|---------|--------|----------------|-----------------|
| S1 | Train binary person/merchant NLModel classifier to replace `businessNameKeywords` list | ICICI/Axis import will expose keyword gaps immediately | 2 weeks | High | Eliminates false-positive person resolution for new banks |
| S2 | Replace `RelationshipClassifier` additive scoring with logistic regression over behavioral signals | Current weights are fabricated; will misclassify significantly as dataset grows | 4 weeks (requires labeled data) | High | Accurate relationship labels drive core product value |
| S3 | Personalized anomaly detection for spending insights (per-user baseline, exponential smoothing) | Alert fatigue risk grows with more data | 3 weeks | Medium | Reduces false alerts; increases insight acceptance rate |
| S4 | Probabilistic cadence model for recurring detection (replace tolerance windows) | Will fail on atypical billing cycles; currently produces false negatives for quarterly and irregular patterns | 4 weeks | Medium | Catches 20-30% more recurring patterns accurately |

---

## Final Verdict

The categorization pipeline is now architecturally sound — the kNN is trained, rules are structural-only, and the feedback loop (user corrections → MLUpdateTask) is wired. The acute risks are in:

1. **Relationship inference** — fully fabricated additive weights, zero calibration
2. **Uncalibrated confidence scores** — shown to users as if they are probabilities
3. **Complete absence of an evaluation harness** — no way to detect regressions

None of these require ML research. They require engineering discipline. Fix evaluation and observability gaps first; the ML investments have no foundation without them.
