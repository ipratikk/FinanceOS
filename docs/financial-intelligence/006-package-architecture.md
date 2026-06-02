---
doc: 006-package-architecture
version: 0.1.0
status: Draft
date: 2026-06-02
---

# Package Architecture — FinanceIntelligence

## Purpose

Define the complete directory structure, module boundaries, target declarations, and inter-module dependency rules for the `FinanceIntelligence` Swift package. This document governs where new code should be placed and what imports are permitted between modules.

---

## Directory Structure

```
Packages/FinanceIntelligence/
├── Package.swift
├── README.md
├── Sources/
│   └── FinanceIntelligence/
│       ├── Models/                         ← Data models (no imports except Foundation)
│       │   ├── TransactionCategory.swift
│       │   ├── TransactionIntent.swift
│       │   ├── IncomeType.swift
│       │   ├── RecurringCadence.swift
│       │   ├── AnomalySignal.swift
│       │   ├── Predictions.swift           ← All prediction structs
│       │   ├── TransactionIntelligence.swift
│       │   ├── FinancialInsight.swift
│       │   ├── InputModels.swift
│       │   └── FeatureModels.swift
│       │
│       ├── Protocols/                      ← Protocol definitions (imports Models only)
│       │   ├── MerchantRecognizer.swift
│       │   ├── CategoryClassifier.swift
│       │   ├── IntentClassifier.swift
│       │   ├── IncomeClassifier.swift
│       │   ├── EmbeddingGenerator.swift
│       │   ├── RecurringDetector.swift
│       │   ├── SubscriptionDetector.swift
│       │   ├── AnomalyDetector.swift
│       │   ├── LinkPredictor.swift
│       │   ├── DescriptionGenerator.swift
│       │   ├── InsightGenerator.swift
│       │   ├── LLMProvider.swift
│       │   ├── ModelRegistry.swift
│       │   ├── IntelligenceLogger.swift
│       │   └── FeedbackStore.swift
│       │
│       ├── Infrastructure/                 ← Registry, logging, config
│       │   ├── LocalModelRegistry.swift
│       │   ├── ModelRegistryYAML.swift
│       │   ├── GRDBIntelligenceLogger.swift
│       │   ├── GRDBFeedbackStore.swift
│       │   ├── IntelligenceContainer.swift  ← DI container
│       │   └── ModelCacheManager.swift
│       │
│       ├── MerchantRecognition/
│       │   ├── CoreMLMerchantRecognizer.swift
│       │   ├── MerchantAliasTable.swift     ← DEPRECATED; kept for fallback only
│       │   └── MerchantFeatureExtractor.swift
│       │
│       ├── Categorization/
│       │   ├── CoreMLCategoryClassifier.swift
│       │   ├── RuleBasedCategorizer.swift   ← DEPRECATED; fallback only
│       │   └── CategoryFeatureExtractor.swift
│       │
│       ├── IntentDetection/
│       │   ├── CoreMLIntentClassifier.swift
│       │   └── IntentFeatureExtractor.swift
│       │
│       ├── IncomeDetection/
│       │   ├── CoreMLIncomeClassifier.swift
│       │   ├── SalaryAnalyzer.swift         ← kept; integrated with Model 6
│       │   └── IncomeFeatureExtractor.swift
│       │
│       ├── Embeddings/
│       │   ├── CoreMLEmbeddingGenerator.swift
│       │   ├── EmbeddingStore.swift         ← GRDB persistence for embeddings
│       │   └── ANNIndex.swift               ← Approximate nearest neighbor index
│       │
│       ├── RecurringDetection/
│       │   ├── CoreMLRecurringDetector.swift
│       │   ├── RecurringFeatureExtractor.swift
│       │   ├── PatternAnalyzer.swift        ← kept; provides sequence to Model 4
│       │   └── RecurringSequenceFetcher.swift
│       │
│       ├── SubscriptionDetection/
│       │   ├── HybridSubscriptionDetector.swift
│       │   └── SubscriptionMerchantList.swift
│       │
│       ├── AnomalyDetection/
│       │   ├── CoreMLAnomalyDetector.swift
│       │   ├── UserHistoryBuilder.swift
│       │   ├── StatisticalAnomalyDetector.swift  ← z-score fallback
│       │   └── AnomalyFeatureExtractor.swift
│       │
│       ├── LinkPrediction/
│       │   ├── MLXLinkPredictor.swift
│       │   └── GraphEmbeddingLoader.swift
│       │
│       ├── DescriptionGeneration/
│       │   ├── MLXDescriptionGenerator.swift
│       │   ├── AppleIntelligenceAdapter.swift
│       │   ├── FallbackGenerator.swift      ← kept; last resort
│       │   └── DescriptionPromptBuilder.swift
│       │
│       ├── InsightGeneration/
│       │   ├── MLXInsightGenerator.swift
│       │   ├── SpendingInsightEngine.swift  ← kept; statistics provider
│       │   └── InsightPromptBuilder.swift
│       │
│       ├── LocalLLM/
│       │   ├── MLXLLMProvider.swift
│       │   ├── ModelManager.swift
│       │   ├── QuantizationManager.swift
│       │   ├── ContextManager.swift
│       │   ├── StreamingInference.swift
│       │   ├── ToolCallingEngine.swift
│       │   └── ConversationMemory.swift
│       │
│       ├── Agent/
│       │   ├── FinanceAgent.swift
│       │   ├── AgentContext.swift
│       │   ├── Tools/
│       │   │   ├── QueryTransactionsTool.swift
│       │   │   ├── QueryBudgetsTool.swift
│       │   │   ├── QueryAccountsTool.swift
│       │   │   ├── QueryInvestmentsTool.swift
│       │   │   ├── QueryCategoriesTool.swift
│       │   │   ├── QueryMerchantsTool.swift
│       │   │   └── QueryRecurringTool.swift
│       │   └── AgentResponseParser.swift
│       │
│       ├── Personalization/
│       │   ├── PersonalizedClassifier.swift
│       │   ├── UserKnowledgeGraph.swift
│       │   ├── PersonalMerchantStore.swift
│       │   ├── PersonalCategoryStore.swift
│       │   └── FeedbackExporter.swift
│       │
│       ├── Pipeline/
│       │   ├── IntelligencePipeline.swift   ← main entry point
│       │   ├── PolicyGate.swift
│       │   ├── StructuralExtractor.swift
│       │   └── PipelineAssembler.swift
│       │
│       ├── Evaluation/                      ← test support, not shipped to prod
│       │   ├── EvaluationHarness.swift
│       │   ├── GoldenDatasetLoader.swift
│       │   └── MetricsCalculator.swift
│       │
│       └── Resources/
│           └── model_registry.yaml
│
└── Tests/
    └── FinanceIntelligenceTests/
        ├── MerchantRecognitionTests.swift
        ├── CategoryClassificationTests.swift
        ├── IntentClassificationTests.swift
        ├── RecurringDetectionTests.swift
        ├── AnomalyDetectionTests.swift
        ├── PipelineIntegrationTests.swift
        ├── PersonalizationTests.swift
        └── Mocks/
            ├── MockMerchantRecognizer.swift
            ├── MockCategoryClassifier.swift
            ├── MockIntentClassifier.swift
            └── MockModelRegistry.swift
```

---

## Module Import Rules

Strict layering enforced via code review (SwiftLint custom rule to be added):

| Module | May Import |
|---|---|
| `Models/` | Foundation only |
| `Protocols/` | Models, Foundation |
| `Infrastructure/` | Protocols, Models, FinanceCore, GRDB |
| `MerchantRecognition/` | Protocols, Models, Infrastructure, CoreML |
| `Categorization/` | Protocols, Models, Infrastructure, CoreML |
| `IntentDetection/` | Protocols, Models, Infrastructure, CoreML |
| `IncomeDetection/` | Protocols, Models, Infrastructure, CoreML |
| `Embeddings/` | Protocols, Models, Infrastructure, CoreML |
| `RecurringDetection/` | Protocols, Models, Infrastructure, CoreML, FinanceCore |
| `SubscriptionDetection/` | RecurringDetection, MerchantRecognition, Protocols |
| `AnomalyDetection/` | Protocols, Models, Infrastructure, CoreML |
| `LinkPrediction/` | Embeddings, Protocols, MLX |
| `DescriptionGeneration/` | Protocols, Models, LocalLLM |
| `InsightGeneration/` | Protocols, Models, LocalLLM |
| `LocalLLM/` | Protocols, MLX |
| `Agent/` | LocalLLM, all detection modules (through Protocols) |
| `Personalization/` | Protocols, Embeddings, Infrastructure |
| `Pipeline/` | All modules |
| `Evaluation/` | All modules (test target only) |

**Prohibited in all production modules:**
- `import SwiftUI`
- `import FinanceUI`
- Direct GRDB access outside `Infrastructure/`

---

## Package.swift

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FinanceIntelligence",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "FinanceIntelligence", targets: ["FinanceIntelligence"])
    ],
    dependencies: [
        .package(path: "../FinanceCore"),
        .package(url: "https://github.com/ml-explore/mlx-swift.git",
                 from: "0.10.0"),
        .package(url: "https://github.com/ml-explore/mlx-swift-examples.git",
                 from: "0.1.0"),
        .package(url: "https://github.com/jpsim/Yams.git",
                 from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "FinanceIntelligence",
            dependencies: [
                .product(name: "FinanceCore", package: "FinanceCore"),
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXLLM", package: "mlx-swift-examples"),
                .product(name: "Yams", package: "Yams"),
            ],
            path: "Sources/FinanceIntelligence",
            resources: [
                .process("Resources/")
            ]
        ),
        .testTarget(
            name: "FinanceIntelligenceTests",
            dependencies: [
                "FinanceIntelligence",
                .product(name: "FinanceTesting", package: "FinanceCore"),
            ],
            path: "Tests/FinanceIntelligenceTests"
        )
    ]
)
```

---

## Module Sizing Targets

Enforce via CI file-size checks:

| Module | Max Files | Max Lines per File |
|---|---|---|
| Models | 10 | 200 |
| Protocols | 15 | 80 |
| Infrastructure | 6 | 300 |
| Each detection module | 4 | 250 |
| LocalLLM | 8 | 300 |
| Agent | 10 | 250 |
| Pipeline | 4 | 200 |

---

## Adding a New Module Checklist

1. Create directory under `Sources/FinanceIntelligence/`
2. Define protocol in `Protocols/`
3. Define input/output models in `Models/`
4. Implement concrete class in new module directory
5. Add mock implementation in `Tests/.../Mocks/`
6. Add test file in `Tests/FinanceIntelligenceTests/`
7. Register model in `model_registry.yaml` (if ML-backed)
8. Wire into `IntelligenceContainer`
9. Wire into `IntelligencePipeline`
10. Update `005-inference-pipeline.md`

---

## Risks

| Risk | Mitigation |
|---|---|
| MLX dependency adds significant binary size | Gate MLX targets behind conditional compilation; MLX models are optional features |
| `Yams` YAML parser adds dependency for model_registry.yaml parsing | Evaluate if JSON registry suffices; YAML chosen for human readability |
| Module boundary drift (infrastructure leaking into detection modules) | SwiftLint custom rule to forbid GRDB imports outside Infrastructure |
| Test target including Evaluation module in prod binary | Ensure Evaluation target is `.testTarget` only; never in product library target |
