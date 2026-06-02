---
doc: 003-target-architecture
version: 0.1.0
status: Draft
date: 2026-06-02
---

# Target Architecture — FinanceIntelligence Platform

## Purpose

Define the complete target architecture for the FinanceIntelligence platform. This document describes every architectural layer, module boundary, data flow, and protocol interface that the platform must implement. Implementation decisions must be evaluated against this blueprint.

---

## Architectural Principles

1. **Swift is an orchestration layer, not a classification layer.** All semantic intelligence originates from trained ML models. Swift loads artifacts, executes inference, and routes results.
2. **Protocol-first design.** Every intelligence capability is expressed as a protocol. Concrete implementations are injected at runtime.
3. **Offline-first.** No network dependency for any production inference path.
4. **Latency budget.** Total pipeline latency for a single transaction < 200 ms on A14 Bionic.
5. **Memory budget.** Total concurrent ML model memory < 150 MB. Individual models < 50 MB.
6. **Testability.** Every module has a mock implementation injectable via protocol.

---

## Five-Layer Architecture

```
+───────────────────────────────────────────────────────────────────+
│  Layer 1: Deterministic Policy                                    │
│  ─────────────────────────────────────────────────────────────── │
│  • Zero-amount gate           • Currency normalization            │
│  • Exact duplicate gate       • Timestamp normalization           │
│  • Invalid account gate       • Direction normalization (CR/DR)   │
│                                                                   │
│  Input: RawTransaction                                            │
│  Output: NormalizedTransaction | .rejected(reason)               │
+───────────────────────────────────────────────────────────────────+
                            │
                            ▼
+───────────────────────────────────────────────────────────────────+
│  Layer 2: Structural Extraction                                   │
│  ─────────────────────────────────────────────────────────────── │
│  • UPIDescriptionParser       • PaymentChannelClassifier          │
│  • AccountExtractor           • ReferenceIDExtractor              │
│  • BankFormatDetector         • RuleEngine (BuiltInRules)         │
│                                                                   │
│  Input: NormalizedTransaction                                     │
│  Output: StructuredTransaction (adds parsed fields)               │
+───────────────────────────────────────────────────────────────────+
                            │
                            ▼
+───────────────────────────────────────────────────────────────────+
│  Layer 3: ML Inference                                            │
│  ─────────────────────────────────────────────────────────────── │
│  Stage 1:  MerchantRecognizer  (Model 1 — CoreML NLModel)        │
│  Stage 2:  CategoryClassifier  (Model 2 — CoreML NLModel)        │
│  Stage 3:  IntentClassifier    (Model 3 — CoreML NLModel)        │
│  Stage 4:  IncomeClassifier    (Model 6 — CoreML NLModel)        │
│  Stage 5:  EmbeddingGenerator  (Model 7 — CoreML Embedding)      │
│  Stage 6:  RecurringDetector   (Model 4 — CoreML Tabular)        │
│  Stage 7:  SubscriptionDetector(Model 5 — Rule + ML hybrid)      │
│  Stage 8:  AnomalyDetector     (Model 9 — CoreML Tabular)        │
│  Stage 9:  LinkPredictor       (Model 8 — MLX, async)            │
│  Stage 10: DescriptionGenerator(Model 10 — MLX LLM, async)      │
│  Stage 11: InsightGenerator    (Model 11 — MLX LLM, async)      │
│                                                                   │
│  PersonalizedClassifier overlay applied after stages 2, 3, 4     │
│  Input: StructuredTransaction                                     │
│  Output: TransactionIntelligence                                  │
+───────────────────────────────────────────────────────────────────+
                            │
                            ▼
+───────────────────────────────────────────────────────────────────+
│  Layer 4: Post-Processing & Enrichment                            │
│  ─────────────────────────────────────────────────────────────── │
│  • KnowledgeGraph enrichment  (GraphBuilder → GraphStore)        │
│  • Entity resolution          (PersonResolver)                    │
│  • Relationship building      (RelationshipEngine)               │
│  • Anomaly aggregation        (AnomalySignal combination)        │
│  • Insight synthesis          (SpendingInsightEngine + Model 11) │
│                                                                   │
│  Input: TransactionIntelligence                                   │
│  Output: EnrichedTransaction                                      │
+───────────────────────────────────────────────────────────────────+
                            │
                            ▼
+───────────────────────────────────────────────────────────────────+
│  Layer 5: Feedback, Personalization & Evaluation                  │
│  ─────────────────────────────────────────────────────────────── │
│  • FeedbackStore              • PersonalizedClassifier update     │
│  • GRDBIntelligenceLogger     • EvaluationHarness                │
│  • UserKnowledgeGraph         • ModelRegistry promotion signal   │
│                                                                   │
│  Async, non-blocking. Does not affect primary pipeline latency.   │
+───────────────────────────────────────────────────────────────────+
```

---

## Module Dependency Graph

```
FinanceCore
    └── Models (TransactionCategory, TransactionIntent, etc.)
    └── Repositories (TransactionRepository, etc.)

FinanceIntelligence
    ├── Protocols/          ← defines all intelligence protocols
    │       depends on: FinanceCore.Models only
    ├── Infrastructure/     ← ModelRegistry, IntelligenceLogger
    │       depends on: Protocols, FinanceCore
    ├── MerchantRecognition/
    │       depends on: Protocols, Infrastructure
    ├── Categorization/
    │       depends on: Protocols, Infrastructure
    ├── IntentDetection/
    │       depends on: Protocols, Infrastructure
    ├── IncomeDetection/
    │       depends on: Protocols, Infrastructure
    ├── Embeddings/
    │       depends on: Protocols, Infrastructure
    ├── RecurringDetection/
    │       depends on: Protocols, Infrastructure
    ├── SubscriptionDetection/
    │       depends on: RecurringDetection, MerchantRecognition
    ├── AnomalyDetection/
    │       depends on: Protocols, Infrastructure, Embeddings
    ├── LinkPrediction/
    │       depends on: Embeddings, KnowledgeGraph
    ├── DescriptionGeneration/
    │       depends on: Protocols, LocalLLM
    ├── InsightGeneration/
    │       depends on: Protocols, LocalLLM
    ├── LocalLLM/
    │       depends on: Protocols, Infrastructure
    ├── Agent/
    │       depends on: LocalLLM, all detection modules
    ├── Personalization/
    │       depends on: Protocols, Embeddings, Infrastructure
    └── Evaluation/
            depends on: all modules (test-only target)

FinanceUI
    └── depends on: FinanceCore, FinanceIntelligence.Protocols ONLY
        (never imports concrete implementations)
```

---

## Protocol Interfaces

### Core Intelligence Protocols

```swift
// MerchantRecognition
protocol MerchantRecognizer {
    func recognize(_ narration: String) async -> MerchantPrediction
}

// Categorization
protocol CategoryClassifier {
    func classify(_ input: CategoryInput) async -> CategoryPrediction
}

// IntentDetection
protocol IntentClassifier {
    func classify(_ input: IntentInput) async -> IntentPrediction
}

// IncomeDetection
protocol IncomeClassifier {
    func classify(_ input: IncomeInput) async -> IncomePrediction
}

// Embeddings
protocol EmbeddingGenerator {
    func embed(_ narration: String) async throws -> EmbeddingVector
}

// RecurringDetection
protocol RecurringDetector {
    func detect(_ sequence: [TransactionFeatures]) async -> RecurringPrediction
}

// SubscriptionDetection
protocol SubscriptionDetector {
    func detect(_ input: SubscriptionInput) async -> SubscriptionPrediction
}

// AnomalyDetection
protocol AnomalyDetector {
    func detect(_ transaction: TransactionFeatures, history: UserHistory) async -> AnomalySignal?
}

// LinkPrediction
protocol LinkPredictor {
    func predict(from source: EntityID, to candidate: EntityID) async -> LinkPrediction
}

// DescriptionGeneration
protocol DescriptionGenerator {
    func generate(_ input: DescriptionInput) async -> String
}

// InsightGeneration
protocol InsightGenerator {
    func generate(_ context: InsightContext) async -> [FinancialInsight]
}

// LLM
protocol LLMProvider {
    func complete(_ prompt: String, options: LLMOptions) async throws -> String
    func stream(_ prompt: String, options: LLMOptions) -> AsyncThrowingStream<String, Error>
}
```

### Infrastructure Protocols

```swift
protocol ModelRegistry {
    func load<T>(_ modelName: ModelName, type: T.Type) throws -> T
    func modelVersion(for name: ModelName) -> ModelVersion?
    func validate(_ name: ModelName) throws
}

protocol IntelligenceLogger {
    func log(_ event: IntelligenceEvent) async
    func queryEvents(filter: EventFilter) async -> [IntelligenceEvent]
}

protocol FeedbackStore {
    func record(_ correction: UserCorrection) async
    func corrections(for transactionID: TransactionID) async -> [UserCorrection]
    func exportTrainingData(format: ExportFormat) async throws -> URL
}
```

---

## Inference Pipeline — Synchronous vs. Asynchronous

### Synchronous Path (< 200 ms target, called per transaction)

Stages 1–8 run synchronously in the pipeline, blocking the caller until complete.

| Stage | Model | Target Latency |
|---|---|---|
| 1 | MerchantRecognizer | < 20 ms |
| 2 | CategoryClassifier | < 20 ms |
| 3 | IntentClassifier | < 15 ms |
| 4 | IncomeClassifier | < 15 ms |
| 5 | EmbeddingGenerator | < 30 ms |
| 6 | RecurringDetector | < 20 ms |
| 7 | SubscriptionDetector | < 10 ms |
| 8 | AnomalyDetector | < 20 ms |
| Layer 4 | KG Enrichment | < 40 ms |
| **Total** | | **< 190 ms** |

### Asynchronous Path (called per-batch or deferred)

Stages 9–11 run asynchronously and do not block transaction persistence.

| Stage | Model | Target Latency |
|---|---|---|
| 9 | LinkPredictor | < 500 ms |
| 10 | DescriptionGenerator | < 2 s |
| 11 | InsightGenerator | < 5 s |

---

## ModelRegistry Wiring

```swift
// AppContainer.swift — dependency composition root
let registry = LocalModelRegistry(bundle: .main, registryPath: "model_registry.yaml")

let container = IntelligenceContainer(
    merchantRecognizer: CoreMLMerchantRecognizer(registry: registry),
    categoryClassifier: CoreMLCategoryClassifier(registry: registry),
    intentClassifier: CoreMLIntentClassifier(registry: registry),
    incomeClassifier: CoreMLIncomeClassifier(registry: registry),
    embeddingGenerator: CoreMLEmbeddingGenerator(registry: registry),
    recurringDetector: CoreMLRecurringDetector(registry: registry),
    subscriptionDetector: HybridSubscriptionDetector(registry: registry),
    anomalyDetector: CoreMLAnomalyDetector(registry: registry),
    linkPredictor: MLXLinkPredictor(registry: registry),
    descriptionGenerator: MLXDescriptionGenerator(registry: registry),
    insightGenerator: MLXInsightGenerator(registry: registry)
)
```

---

## Personalization Overlay

Applied after Stages 2, 3, and 4 (category, intent, income predictions).

```
CoreML Base Prediction
        │
        ▼
PersonalizedClassifier.override(prediction, narration, transactionID)
        │
        ├── IF kNN match found AND confidence > threshold
        │         └── return corrected label + source: .personalized
        │
        └── ELSE
                  └── return base prediction + source: .model
```

PersonalizedClassifier stores corrected examples as (embedding, correctedLabel) pairs. Lookup is ANN search over embedding space (Model 7 required).

---

## Package.swift Dependencies

```swift
// Packages/FinanceIntelligence/Package.swift
let package = Package(
    name: "FinanceIntelligence",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "FinanceIntelligence", targets: ["FinanceIntelligence"])
    ],
    dependencies: [
        .package(path: "../FinanceCore"),
        // MLX Swift — for LLM inference (Models 10, 11, 8)
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.10.0"),
        .package(url: "https://github.com/ml-explore/mlx-swift-examples", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "FinanceIntelligence",
            dependencies: [
                "FinanceCore",
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXLLM", package: "mlx-swift-examples"),
            ],
            resources: [.process("Resources/")]
        ),
        .testTarget(
            name: "FinanceIntelligenceTests",
            dependencies: ["FinanceIntelligence", "FinanceTesting"]
        )
    ]
)
```

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| MLX memory footprint exceeds device budget | Medium | High | Gate MLX models on device capability check at runtime |
| CoreML model load latency on cold start | Low | Medium | Preload models on app launch in background task |
| PersonalizedClassifier degrades on sparse user data | High | Low | Fall through to base model when kNN confidence < threshold |
| Model overfitting on synthetic training data | Medium | High | Evaluate on held-out real transaction set; use real data augmentation |
| Protocol proliferation creates maintenance burden | Low | Medium | Enforce one protocol per capability; no protocol inheritance chains |
