# FinanceOS Transaction Intelligence Platform — Architecture Document

**Version:** 1.0  
**Status:** Design  
**Authors:** Engineering  
**Last Updated:** 2026-05-30

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Current State vs Target State](#2-current-state-vs-target-state)
3. [System Architecture Overview](#3-system-architecture-overview)
4. [Intelligence Pipeline](#4-intelligence-pipeline)
5. [Package Structure](#5-package-structure)
6. [Domain Models](#6-domain-models)
7. [Repository Interfaces](#7-repository-interfaces)
8. [GRDB Schema](#8-grdb-schema)
9. [Knowledge Graph Design](#9-knowledge-graph-design)
10. [CoreML Architecture](#10-coreml-architecture)
11. [Merchant Intelligence](#11-merchant-intelligence)
12. [Categorization & Intent Engine](#12-categorization--intent-engine)
13. [Recurring Detection](#13-recurring-detection)
14. [Relationship Engine](#14-relationship-engine)
15. [Behavior Intelligence](#15-behavior-intelligence)
16. [Description Generation](#16-description-generation)
17. [Sequence Diagrams](#17-sequence-diagrams)
18. [Testing Strategy](#18-testing-strategy)
19. [Migration Strategy](#19-migration-strategy)
20. [Performance Strategy](#20-performance-strategy)
21. [Incremental Learning Strategy](#21-incremental-learning-strategy)
22. [Apple Intelligence Integration](#22-apple-intelligence-integration)
23. [Risk Analysis](#23-risk-analysis)
24. [Implementation Roadmap](#24-implementation-roadmap)

---

## 1. Executive Summary

FinanceOS Transaction Intelligence Platform converts raw bank statement narrations — noisy, bank-specific, often cryptic strings — into structured financial intelligence: who, what, why, how often.

### Core Invariants

- **No LLMs for classification.** Apple Intelligence generates language only; rules, graphs, and on-device models decide all financial meaning.
- **Offline-first.** Zero transaction data leaves the device.
- **Deterministic before ML.** Rules + entity resolution + graph analysis targets >90% accuracy. CoreML handles the remaining tail.
- **Auditable.** Every decision has a traceable provenance: which rule, which alias, which model version, which confidence.
- **Gets smarter.** Each imported statement generates new training signals. The system improves automatically without user action.

### Target Accuracy (Phased)

| Phase | Mechanism | Target |
|-------|-----------|--------|
| Phase 1 | Rule Engine + Alias Table | 60% |
| Phase 2 | + Knowledge Graph + Historical | 80% |
| Phase 3 | + Relationship Engine + Behavior | 88% |
| Phase 4 | + CoreML | 92% |
| Phase 5 | + Incremental learning | 95%+ |

---

## 2. Current State vs Target State

### What Exists Today

```
FinanceIntelligence (current)
├── Categorization/
│   ├── CoreMLCategorizer         — conditional CoreML inference
│   ├── RuleBasedCategorizer      — keyword rules → category
│   ├── TransactionIntelligenceService (protocol)
│   └── TransactionIntelligenceServiceImpl (actor)
├── Corrections/
│   └── UserCorrectionStore       — disk-persisted user corrections
├── Domain/
│   ├── AnalyzedTransaction       — output of pipeline
│   ├── CategoryPrediction        — category + confidence
│   ├── CategoryTaxonomy          — v1 (19 categories)
│   ├── MerchantCandidate         — normalized merchant
│   ├── TransactionFeatures       — ML feature vector
│   ├── TransactionInsight        — recurring/spike detection
│   └── UserCorrection            — stored user override
├── Features/
│   ├── TransactionFeatureExtractor
│   └── UPIDescriptionParser
├── Insights/
│   └── SpendingInsightEngine     — statistical insight gen
├── Learning/
│   ├── BundledSeeds              — initial alias seeds
│   ├── LocalTransactionLearner   — k-NN from corrections
│   └── PersonalizedClassifier    — user-personalized wrapper
└── MerchantNormalization/
    ├── MerchantAliasTable        — ~40 merchants, JSON
    ├── MerchantNormalizer        — orchestrates 4 stages
    └── MerchantTextCleaner       — strips noise prefixes
```

### What Is Missing (Target)

| Capability | Status |
|-----------|--------|
| Intent Engine (separate from category) | Missing |
| Knowledge Graph (nodes + edges) | Missing |
| Person / Payee Resolution | Missing |
| Relationship Engine (friend/landlord/etc) | Missing |
| Advanced Recurring Detection | Partial |
| Behavior Intelligence (salary/rent/SIP cycles) | Missing |
| GRDB persistence for intelligence entities | Missing |
| Embedding generation + similarity search | Missing |
| Apple Intelligence description generation | Missing |
| Incremental model retraining pipeline | Missing |

### Transaction Model Gaps

`Transaction` already has `categoryId` and `merchantName`. Still needed:

```swift
// Fields to add to Transaction (via migration)
var intentId: String?             // e.g. "credit_card_payment"
var resolvedPersonId: UUID?       // FK to persons table
var recurringPatternId: UUID?     // FK to recurring_patterns
var intelligenceVersion: String?  // which pipeline version classified this
```

---

## 3. System Architecture Overview

### Package Dependency Graph

```
FinanceApp (iOS + macOS targets)
    │
    ├── FinanceUI
    │       └── FinanceCore (models, protocols only)
    │
    ├── FinanceCore
    │       ├── GRDB
    │       └── FinanceParsers (import pipeline)
    │
    └── FinanceIntelligence  ← Primary focus of this document
            ├── FinanceCore (Transaction, Ledger models)
            └── CoreML (conditional, compile-time flag)
```

### Layer Architecture

```
┌─────────────────────────────────────────────────────┐
│                      FinanceUI                       │
│    Views ←→ ViewModels ←→ Domain Models (no GRDB)   │
└──────────────────────┬──────────────────────────────┘
                       │ IntelligenceContext, AnalyzedTransaction
┌──────────────────────▼──────────────────────────────┐
│              FinanceIntelligence                      │
│                                                       │
│  ┌─────────────┐  ┌────────────┐  ┌───────────────┐ │
│  │  Rule Engine │  │ Knowledge  │  │  Description  │ │
│  │  Intent Eng  │  │   Graph    │  │  Generator    │ │
│  │  Recurring   │  │  GraphQL   │  │  (Apple Intel)│ │
│  └──────┬──────┘  └─────┬──────┘  └───────────────┘ │
│         │               │                             │
│  ┌──────▼──────┐  ┌─────▼──────┐  ┌───────────────┐ │
│  │  Merchant   │  │ Relationship│  │   CoreML      │ │
│  │  Resolver   │  │   Engine   │  │   Models      │ │
│  └──────┬──────┘  └─────┬──────┘  └───────┬───────┘ │
│         │               │                  │          │
│  ┌──────▼───────────────▼──────────────────▼───────┐ │
│  │            Persistence (GRDB via Repositories)   │ │
│  └─────────────────────────────────────────────────┘ │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│                   FinanceCore                         │
│         DatabaseManager  AppContainer  GRDB          │
└─────────────────────────────────────────────────────┘
```

### UI Decoupling Rule

```
FinanceUI NEVER imports:
  - GRDB
  - CoreML
  - FinanceParsers
  - Any FinanceIntelligence persistence type

FinanceUI sees ONLY:
  - AnalyzedTransaction
  - TransactionInsight
  - CategoryTaxonomy
  - Merchant display strings
```

---

## 4. Intelligence Pipeline

### Full Pipeline (per transaction)

```
Raw Transaction (description: String)
        │
        ▼
┌───────────────────┐
│ Feature Extractor │  → TransactionFeatures (tokens, booleans, amount, temporal)
└────────┬──────────┘
         │
         ▼
┌────────────────────────────────────────────────────────┐
│                   STAGE 1: RULE ENGINE                  │
│  RuleEngine → applies ordered rules to TransactionFeatures
│  Output: RuleEngineResult (categoryId, intentId, confidence)
│  Signal: hasPayrollIndicator, hasTransferIndicator, etc.
└────────────────────┬───────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────┐
│              STAGE 2: ENTITY RESOLUTION                 │
│  MerchantResolver  → canonical merchant + merchantId    │
│  PersonResolver    → resolved person entity + personId  │
│  AliasResolver     → maps raw narration to known entity │
│  Output: ResolvedEntities                               │
└────────────────────┬───────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────┐
│            STAGE 3: HISTORICAL ANALYSIS                 │
│  HistoricalAnalyzer → query past transactions with      │
│    same merchant/person/amount pattern                  │
│  If historical match: inherit category + intent + conf  │
│  Output: HistoricalSignal                               │
└────────────────────┬───────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────┐
│             STAGE 4: KNOWLEDGE GRAPH                    │
│  GraphStore.query(entityId) → node + edges              │
│  Traverse: PAID_TO, RECURS_WITH, CLASSIFIED_AS          │
│  Output: GraphSignal (entity metadata, relationships)   │
└────────────────────┬───────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────┐
│               STAGE 5: COREML INFERENCE                 │
│  Only when: rule confidence < 0.8 AND no historical hit │
│  MerchantClassifier → merchantId (if not resolved)      │
│  CategoryClassifier → categoryId                        │
│  Output: MLPrediction                                   │
└────────────────────┬───────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────┐
│               STAGE 6: SIGNAL FUSION                   │
│  SignalFuser merges all stage outputs with weights:      │
│    user_correction: 1.0 (overrides all)                 │
│    rule_engine:     0.95                                │
│    historical:      0.90                                │
│    graph:           0.85                                │
│    coreml:          0.75                                │
│    alias_table:     0.70                                │
│    fallback_rules:  0.50                                │
│  Output: FusedPrediction                                │
└────────────────────┬───────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────┐
│           STAGE 7: DESCRIPTION GENERATION               │
│  DescriptionContext built from FusedPrediction          │
│  FallbackGenerator: deterministic template strings      │
│  AppleIntelligenceAdapter: natural language (iOS 18+)   │
│  Output: humanReadableDescription                       │
└────────────────────┬───────────────────────────────────┘
                     │
                     ▼
              EnrichedTransaction
```

### Confidence Thresholds

| Threshold | Action |
|-----------|--------|
| ≥ 0.90 | Persist, no UI flag |
| 0.75–0.89 | Persist, show confidence indicator in UI |
| 0.50–0.74 | Persist, flag for user review |
| < 0.50 | Persist as `uncategorized`, prompt user |

### Batch Pipeline

Batch analysis uses structured concurrency with bounded parallelism:

```swift
// Process in chunks to respect memory constraints
// Chunk size: 50 transactions per task group child
// Stages 1-4 run sequentially per transaction
// Stage 5 (CoreML) batched if needed for efficiency
```

---

## 5. Package Structure

### Target Directory Layout

```
Packages/FinanceIntelligence/Sources/FinanceIntelligence/
│
├── Domain/                         (pure value types, no persistence)
│   ├── AnalyzedTransaction.swift   (exists — extend)
│   ├── CategoryPrediction.swift    (exists — extend)
│   ├── CategoryTaxonomy.swift      (exists — extend with intents)
│   ├── MerchantCandidate.swift     (exists — extend)
│   ├── TransactionFeatures.swift   (exists — extend)
│   ├── TransactionInsight.swift    (exists — extend)
│   ├── UserCorrection.swift        (exists)
│   ├── ModelMetadata.swift         (exists)
│   ├── IntentTaxonomy.swift        ← NEW
│   ├── EnrichedTransaction.swift   ← NEW
│   ├── ResolvedEntities.swift      ← NEW
│   ├── FusedPrediction.swift       ← NEW
│   ├── Person.swift                ← NEW
│   ├── Relationship.swift          ← NEW
│   ├── RecurringPattern.swift      ← NEW
│   └── BehaviorPattern.swift       ← NEW
│
├── Pipeline/                       ← NEW
│   ├── IntelligencePipeline.swift
│   ├── PipelineStage.swift
│   ├── SignalFuser.swift
│   └── IntelligenceConfiguration.swift
│
├── RuleEngine/                     ← NEW (replaces RuleBasedCategorizer)
│   ├── RuleEngine.swift
│   ├── RuleEngineResult.swift
│   ├── RuleSet.swift
│   ├── Rule.swift
│   ├── IntentRule.swift
│   └── RuleLoader.swift
│
├── MerchantIntelligence/          (replace MerchantNormalization/)
│   ├── MerchantResolver.swift      ← NEW (orchestrator)
│   ├── MerchantTextCleaner.swift   (exists)
│   ├── MerchantNormalizer.swift    (exists — refactor)
│   ├── MerchantAliasTable.swift    (exists — expand to 300+)
│   ├── AliasResolver.swift         ← NEW
│   ├── EmbeddingIndex.swift        ← NEW
│   └── MerchantConfidenceScorer.swift ← NEW
│
├── EntityResolution/              ← NEW
│   ├── PersonResolver.swift
│   ├── PersonEntityStore.swift
│   ├── ResolvedEntities.swift
│   └── UPIDescriptionParser.swift  (move from Features/)
│
├── Historical/                    ← NEW
│   ├── HistoricalAnalyzer.swift
│   └── HistoricalSignal.swift
│
├── KnowledgeGraph/                ← NEW
│   ├── GraphStore.swift
│   ├── GraphNode.swift
│   ├── GraphEdge.swift
│   ├── GraphBuilder.swift
│   ├── GraphQueries.swift
│   └── GraphAlgorithms.swift
│
├── Recurring/                     (extend Insights/)
│   ├── RecurringDetector.swift
│   ├── PatternAnalyzer.swift
│   └── ScheduleInference.swift
│
├── Relationships/                 ← NEW
│   ├── RelationshipEngine.swift
│   ├── RelationshipClassifier.swift
│   └── RelationshipSignals.swift
│
├── Behavior/                      ← NEW
│   ├── SalaryAnalyzer.swift
│   ├── SpendingAnalyzer.swift
│   ├── CashflowAnalyzer.swift
│   └── FinancialRoutineDetector.swift
│
├── MachineLearning/               (extend Categorization/ + Learning/)
│   ├── CoreMLCategorizer.swift     (exists)
│   ├── LocalTransactionLearner.swift (exists)
│   ├── PersonalizedClassifier.swift (exists)
│   ├── MerchantClassifier.swift    ← NEW
│   ├── RelationshipClassifier.swift ← NEW
│   ├── EmbeddingGenerator.swift    ← NEW
│   └── ModelManager.swift          ← NEW
│
├── DescriptionGeneration/         ← NEW
│   ├── DescriptionContext.swift
│   ├── DescriptionGenerator.swift
│   ├── AppleIntelligenceAdapter.swift
│   └── FallbackGenerator.swift
│
├── Persistence/                   ← NEW
│   ├── Repositories/
│   │   ├── IntelligenceMerchantRepository.swift
│   │   ├── IntelligencePersonRepository.swift
│   │   ├── RecurringPatternRepository.swift
│   │   ├── RelationshipRepository.swift
│   │   ├── GraphRepository.swift
│   │   └── EmbeddingRepository.swift
│   ├── GRDBModels/
│   │   ├── GRDBMerchant.swift
│   │   ├── GRDBMerchantAlias.swift
│   │   ├── GRDBPerson.swift
│   │   ├── GRDBRelationship.swift
│   │   ├── GRDBRecurringPattern.swift
│   │   ├── GRDBGraphNode.swift
│   │   ├── GRDBGraphEdge.swift
│   │   └── GRDBEmbedding.swift
│   └── Migrations/
│       ├── IntelligenceMigration_v1.swift
│       └── IntelligenceMigration_v2.swift
│
├── Corrections/
│   └── UserCorrectionStore.swift   (exists)
│
├── Features/
│   └── TransactionFeatureExtractor.swift (exists — extend)
│
└── Insights/
    └── SpendingInsightEngine.swift (exists — keep)
```

---

## 6. Domain Models

### 6.1 IntentTaxonomy

```swift
// FinanceIntelligence/Domain/IntentTaxonomy.swift

public enum TransactionIntent: String, Codable, Sendable, CaseIterable {
    case salary              = "salary"
    case rent                = "rent"
    case investment          = "investment"
    case mutualFundSIP       = "mutual_fund_sip"
    case insurance           = "insurance"
    case subscription        = "subscription"
    case creditCardPayment   = "credit_card_payment"
    case loanPayment         = "loan_payment"
    case cashWithdrawal      = "cash_withdrawal"
    case refund              = "refund"
    case cashback            = "cashback"
    case transfer            = "transfer"
    case interestPayment     = "interest_payment"
    case utilityBill         = "utility_bill"
    case shopping            = "shopping"
    case groceries           = "groceries"
    case food                = "food"
    case travel              = "travel"
    case healthcare          = "healthcare"
    case income              = "income"
    case unknown             = "unknown"

    public var displayName: String { ... }
}

// Intent ≠ Category.
// Example: AmEx payment → category: "fees", intent: "credit_card_payment"
// Example: ICICI SIP → category: "transfers", intent: "mutual_fund_sip"
```

### 6.2 EnrichedTransaction

```swift
// FinanceIntelligence/Domain/EnrichedTransaction.swift

public struct EnrichedTransaction: Sendable {
    public let transaction: Transaction
    public let merchantCandidate: MerchantCandidate
    public let categoryPrediction: CategoryPrediction
    public let intentPrediction: IntentPrediction
    public let features: TransactionFeatures
    public let resolvedEntities: ResolvedEntities
    public let recurringContext: RecurringContext?
    public let relationshipContext: RelationshipContext?
    public let humanDescription: String
    public let isUserCorrected: Bool
    public let pipelineVersion: String
}

public struct IntentPrediction: Sendable {
    public let intent: TransactionIntent
    public let confidence: Double
    public let source: PredictionSource
}

public struct RecurringContext: Sendable {
    public let patternId: UUID
    public let cadence: RecurringCadence
    public let confidence: Double
    public let expectedNextDate: Date?
}

public struct RelationshipContext: Sendable {
    public let personId: UUID
    public let personName: String
    public let relationship: RelationshipType
    public let confidence: Double
}
```

### 6.3 Person

```swift
// FinanceIntelligence/Domain/Person.swift

public struct Person: Identifiable, Sendable, Codable {
    public let id: UUID
    public var canonicalName: String
    public var aliases: [String]
    public var upiHandle: String?
    public var accountNumberSuffix: String?
    public var inferredRelationship: RelationshipType?
    public var relationshipConfidence: Double
    public var totalTransactionCount: Int
    public var firstSeenAt: Date
    public var lastSeenAt: Date
}

public enum RelationshipType: String, Codable, Sendable, CaseIterable {
    case landlord       = "landlord"
    case tenant         = "tenant"
    case friend         = "friend"
    case family         = "family"
    case employer       = "employer"
    case employee       = "employee"
    case loanProvider   = "loan_provider"
    case loanRecipient  = "loan_recipient"
    case reimbursement  = "reimbursement"
    case unknown        = "unknown"
}
```

### 6.4 RecurringPattern

```swift
// FinanceIntelligence/Domain/RecurringPattern.swift

public struct RecurringPattern: Identifiable, Sendable, Codable {
    public let id: UUID
    public let merchantId: UUID?
    public let personId: UUID?
    public let categoryId: String
    public let intentId: String
    public var cadence: RecurringCadence
    public var averageAmountMinorUnits: Int64
    public var amountVariancePercent: Double
    public var dayOfMonthHint: Int?
    public var confidence: Double
    public var lastSeenAt: Date
    public var occurrenceCount: Int
}

public enum RecurringCadence: String, Codable, Sendable {
    case weekly     = "weekly"
    case biWeekly   = "bi_weekly"
    case monthly    = "monthly"
    case quarterly  = "quarterly"
    case yearly     = "yearly"
    case irregular  = "irregular"
}
```

### 6.5 Relationship

```swift
// FinanceIntelligence/Domain/Relationship.swift

public struct Relationship: Identifiable, Sendable, Codable {
    public let id: UUID
    public let fromPersonId: UUID?       // nil = self (the user)
    public let toPersonId: UUID?
    public let fromMerchantId: UUID?
    public let toMerchantId: UUID?
    public let type: RelationshipType
    public var confidence: Double
    public var evidenceCount: Int
    public var inferredFrom: [RelationshipSignal]
}

public enum RelationshipSignal: String, Codable, Sendable {
    case recurringAmount        // same amount monthly
    case postSalaryTiming       // occurs days after salary credit
    case roundNumber            // amount is round (rent heuristic)
    case regularInterval        // consistent date pattern
    case upiLabel               // UPI label contains keywords
    case historicalPattern      // corroborated by history
}
```

### 6.6 BehaviorPattern

```swift
// FinanceIntelligence/Domain/BehaviorPattern.swift

public struct BehaviorPattern: Sendable, Codable {
    public let salaryCycle: SalaryCycle?
    public let rentCycle: RecurringPattern?
    public let creditCardPayoffCycle: RecurringPattern?
    public let sipCycle: RecurringPattern?
    public let monthlyCashFlow: CashFlowSummary
}

public struct SalaryCycle: Sendable, Codable {
    public let averageDayOfMonth: Int
    public let averageAmountMinorUnits: Int64
    public let confidence: Double
    public let sources: [UUID]  // transaction IDs
}

public struct CashFlowSummary: Sendable, Codable {
    public let averageMonthlyIncome: Int64
    public let averageMonthlyExpense: Int64
    public let savingsRate: Double
}
```

### 6.7 GraphNode / GraphEdge

```swift
// FinanceIntelligence/Domain/GraphNode.swift

public enum GraphNodeType: String, Codable, Sendable {
    case merchant           = "merchant"
    case person             = "person"
    case transaction        = "transaction"
    case category           = "category"
    case account            = "account"
    case institution        = "institution"
    case recurringPattern   = "recurring_pattern"
}

public struct GraphNode: Identifiable, Sendable, Codable {
    public let id: UUID
    public let nodeType: GraphNodeType
    public let externalId: String   // UUID or string ID of referenced entity
    public let label: String
    public var properties: [String: String]
}

public enum GraphEdgeType: String, Codable, Sendable {
    case paidTo         = "PAID_TO"
    case paidFrom       = "PAID_FROM"
    case belongsTo      = "BELONGS_TO"
    case relatedTo      = "RELATED_TO"
    case recursWith     = "RECURS_WITH"
    case classifiedAs   = "CLASSIFIED_AS"
    case worksFor       = "WORKS_FOR"
    case paysRentTo     = "PAYS_RENT_TO"
    case paysCardTo     = "PAYS_CARD_TO"
    case investsWith    = "INVESTS_WITH"
}

public struct GraphEdge: Identifiable, Sendable, Codable {
    public let id: UUID
    public let fromNodeId: UUID
    public let toNodeId: UUID
    public let edgeType: GraphEdgeType
    public var weight: Double           // strength of relationship
    public var observationCount: Int    // number of transactions that contributed
    public var lastObservedAt: Date
}
```

---

## 7. Repository Interfaces

All repositories follow the existing FinanceCore pattern: protocol + GRDB implementation, injected via AppContainer.

### 7.1 IntelligenceMerchantRepository

```swift
public protocol IntelligenceMerchantRepository: Sendable {
    func fetchByCanonicalName(_ name: String) async throws -> IntelligenceMerchant?
    func fetchByAlias(_ alias: String) async throws -> IntelligenceMerchant?
    func fetchAll() async throws -> [IntelligenceMerchant]
    func save(_ merchant: IntelligenceMerchant) async throws
    func saveAlias(_ alias: MerchantAlias) async throws
    func delete(id: UUID) async throws
}
```

### 7.2 PersonRepository

```swift
public protocol PersonRepository: Sendable {
    func fetchByCanonicalName(_ name: String) async throws -> Person?
    func fetchByUPIHandle(_ handle: String) async throws -> Person?
    func fetchByAlias(_ alias: String) async throws -> Person?
    func fetchAll() async throws -> [Person]
    func save(_ person: Person) async throws
    func addAlias(personId: UUID, alias: String) async throws
}
```

### 7.3 RecurringPatternRepository

```swift
public protocol RecurringPatternRepository: Sendable {
    func fetchByMerchant(merchantId: UUID) async throws -> RecurringPattern?
    func fetchByPerson(personId: UUID) async throws -> RecurringPattern?
    func fetchAll() async throws -> [RecurringPattern]
    func save(_ pattern: RecurringPattern) async throws
    func incrementOccurrence(patternId: UUID, amount: Int64, date: Date) async throws
}
```

### 7.4 RelationshipRepository

```swift
public protocol RelationshipRepository: Sendable {
    func fetchRelationships(forPersonId: UUID) async throws -> [Relationship]
    func fetchRelationships(forMerchantId: UUID) async throws -> [Relationship]
    func save(_ relationship: Relationship) async throws
    func updateConfidence(id: UUID, confidence: Double) async throws
}
```

### 7.5 GraphRepository

```swift
public protocol GraphRepository: Sendable {
    func fetchNode(id: UUID) async throws -> GraphNode?
    func fetchNodeByExternalId(_ externalId: String, type: GraphNodeType) async throws -> GraphNode?
    func fetchEdges(fromNodeId: UUID) async throws -> [GraphEdge]
    func fetchEdges(toNodeId: UUID) async throws -> [GraphEdge]
    func fetchEdges(fromNodeId: UUID, type: GraphEdgeType) async throws -> [GraphEdge]
    func saveNode(_ node: GraphNode) async throws -> GraphNode
    func saveEdge(_ edge: GraphEdge) async throws
    func incrementEdgeWeight(id: UUID, by delta: Double) async throws
    func fetchNeighbors(nodeId: UUID, depth: Int) async throws -> [GraphNode]
}
```

### 7.6 EmbeddingRepository

```swift
public protocol EmbeddingRepository: Sendable {
    func fetchEmbedding(entityId: UUID) async throws -> StoredEmbedding?
    func save(_ embedding: StoredEmbedding) async throws
    func fetchNearestNeighbors(
        vector: [Float],
        entityType: EmbeddingEntityType,
        limit: Int
    ) async throws -> [(entity: UUID, distance: Float)]
}

public struct StoredEmbedding: Sendable, Codable {
    public let id: UUID
    public let entityId: UUID
    public let entityType: EmbeddingEntityType
    public let vector: [Float]
    public let modelVersion: String
    public let createdAt: Date
}

public enum EmbeddingEntityType: String, Codable, Sendable {
    case merchant = "merchant"
    case person   = "person"
    case narration = "narration"
}
```

---

## 8. GRDB Schema

All intelligence tables live in the same SQLite database managed by `DatabaseManager`. New tables are added via `AppMigration`.

### 8.1 Transaction Table Extensions

```sql
-- Via new AppMigration (v2)
ALTER TABLE transactions ADD COLUMN intentId TEXT;
ALTER TABLE transactions ADD COLUMN resolvedPersonId TEXT REFERENCES persons(id);
ALTER TABLE transactions ADD COLUMN recurringPatternId TEXT REFERENCES recurring_patterns(id);
ALTER TABLE transactions ADD COLUMN intelligenceVersion TEXT;

CREATE INDEX idx_transactions_resolvedPersonId ON transactions(resolvedPersonId);
CREATE INDEX idx_transactions_recurringPatternId ON transactions(recurringPatternId);
```

### 8.2 merchants

```sql
CREATE TABLE merchants (
    id TEXT PRIMARY KEY,
    canonicalName TEXT NOT NULL,
    category TEXT,
    subcategory TEXT,
    website TEXT,
    logoUrl TEXT,
    isVerified INTEGER NOT NULL DEFAULT 0,
    transactionCount INTEGER NOT NULL DEFAULT 0,
    createdAt DATETIME NOT NULL,
    updatedAt DATETIME NOT NULL
);

CREATE UNIQUE INDEX idx_merchants_canonicalName ON merchants(canonicalName);
CREATE INDEX idx_merchants_category ON merchants(category);
```

### 8.3 merchant_aliases

```sql
CREATE TABLE merchant_aliases (
    id TEXT PRIMARY KEY,
    merchantId TEXT NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    alias TEXT NOT NULL,
    matchType TEXT NOT NULL,  -- 'exact', 'prefix', 'substring', 'regex', 'fuzzy'
    confidence REAL NOT NULL DEFAULT 0.92,
    createdAt DATETIME NOT NULL
);

CREATE UNIQUE INDEX idx_merchant_aliases_alias ON merchant_aliases(alias);
CREATE INDEX idx_merchant_aliases_merchantId ON merchant_aliases(merchantId);
```

### 8.4 persons

```sql
CREATE TABLE persons (
    id TEXT PRIMARY KEY,
    canonicalName TEXT NOT NULL,
    upiHandle TEXT,
    accountNumberSuffix TEXT,
    inferredRelationship TEXT,
    relationshipConfidence REAL NOT NULL DEFAULT 0.0,
    transactionCount INTEGER NOT NULL DEFAULT 0,
    firstSeenAt DATETIME NOT NULL,
    lastSeenAt DATETIME NOT NULL
);

CREATE INDEX idx_persons_canonicalName ON persons(canonicalName);
CREATE INDEX idx_persons_upiHandle ON persons(upiHandle);
```

### 8.5 person_aliases

```sql
CREATE TABLE person_aliases (
    id TEXT PRIMARY KEY,
    personId TEXT NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    alias TEXT NOT NULL,
    createdAt DATETIME NOT NULL
);

CREATE UNIQUE INDEX idx_person_aliases_alias ON person_aliases(alias);
CREATE INDEX idx_person_aliases_personId ON person_aliases(personId);
```

### 8.6 relationships

```sql
CREATE TABLE relationships (
    id TEXT PRIMARY KEY,
    fromPersonId TEXT REFERENCES persons(id),
    toPersonId TEXT REFERENCES persons(id),
    fromMerchantId TEXT REFERENCES merchants(id),
    toMerchantId TEXT REFERENCES merchants(id),
    relationshipType TEXT NOT NULL,
    confidence REAL NOT NULL DEFAULT 0.0,
    evidenceCount INTEGER NOT NULL DEFAULT 0,
    inferredSignals TEXT NOT NULL DEFAULT '[]',  -- JSON array of RelationshipSignal
    createdAt DATETIME NOT NULL,
    updatedAt DATETIME NOT NULL
);

CREATE INDEX idx_relationships_fromPersonId ON relationships(fromPersonId);
CREATE INDEX idx_relationships_toPersonId ON relationships(toPersonId);
```

### 8.7 recurring_patterns

```sql
CREATE TABLE recurring_patterns (
    id TEXT PRIMARY KEY,
    merchantId TEXT REFERENCES merchants(id),
    personId TEXT REFERENCES persons(id),
    categoryId TEXT NOT NULL,
    intentId TEXT NOT NULL,
    cadence TEXT NOT NULL,             -- 'weekly','monthly','quarterly','yearly','irregular'
    averageAmountMinorUnits INTEGER NOT NULL,
    amountVariancePercent REAL NOT NULL DEFAULT 0.0,
    dayOfMonthHint INTEGER,
    confidence REAL NOT NULL DEFAULT 0.0,
    occurrenceCount INTEGER NOT NULL DEFAULT 0,
    lastSeenAt DATETIME NOT NULL,
    createdAt DATETIME NOT NULL
);

CREATE INDEX idx_recurring_merchantId ON recurring_patterns(merchantId);
CREATE INDEX idx_recurring_personId ON recurring_patterns(personId);
CREATE INDEX idx_recurring_cadence ON recurring_patterns(cadence);
```

### 8.8 knowledge_graph_nodes

```sql
CREATE TABLE knowledge_graph_nodes (
    id TEXT PRIMARY KEY,
    nodeType TEXT NOT NULL,     -- 'merchant','person','transaction','category','account'
    externalId TEXT NOT NULL,
    label TEXT NOT NULL,
    properties TEXT NOT NULL DEFAULT '{}',  -- JSON
    createdAt DATETIME NOT NULL
);

CREATE UNIQUE INDEX idx_graph_nodes_external ON knowledge_graph_nodes(nodeType, externalId);
CREATE INDEX idx_graph_nodes_type ON knowledge_graph_nodes(nodeType);
```

### 8.9 knowledge_graph_edges

```sql
CREATE TABLE knowledge_graph_edges (
    id TEXT PRIMARY KEY,
    fromNodeId TEXT NOT NULL REFERENCES knowledge_graph_nodes(id) ON DELETE CASCADE,
    toNodeId TEXT NOT NULL REFERENCES knowledge_graph_nodes(id) ON DELETE CASCADE,
    edgeType TEXT NOT NULL,
    weight REAL NOT NULL DEFAULT 1.0,
    observationCount INTEGER NOT NULL DEFAULT 1,
    lastObservedAt DATETIME NOT NULL,
    createdAt DATETIME NOT NULL
);

CREATE UNIQUE INDEX idx_graph_edges_unique ON knowledge_graph_edges(fromNodeId, toNodeId, edgeType);
CREATE INDEX idx_graph_edges_from ON knowledge_graph_edges(fromNodeId);
CREATE INDEX idx_graph_edges_to ON knowledge_graph_edges(toNodeId);
CREATE INDEX idx_graph_edges_type ON knowledge_graph_edges(edgeType);
```

### 8.10 embeddings

```sql
CREATE TABLE embeddings (
    id TEXT PRIMARY KEY,
    entityId TEXT NOT NULL,
    entityType TEXT NOT NULL,   -- 'merchant','person','narration'
    vector BLOB NOT NULL,       -- Float32 array, little-endian packed
    modelVersion TEXT NOT NULL,
    createdAt DATETIME NOT NULL
);

CREATE INDEX idx_embeddings_entity ON embeddings(entityType, entityId);
```

> **Note:** SQLite has no native vector similarity search. Embeddings are loaded into memory for nearest-neighbor computation using a lightweight Swift k-d tree or brute-force cosine similarity over top-N candidates. At 10,000 merchants × 128 dims = ~5MB, this is viable on-device.

### 8.11 intelligence_model_metadata

```sql
CREATE TABLE intelligence_model_metadata (
    id TEXT PRIMARY KEY,
    modelName TEXT NOT NULL UNIQUE,
    modelVersion TEXT NOT NULL,
    accuracy REAL,
    trainedAt DATETIME,
    sampleCount INTEGER,
    isActive INTEGER NOT NULL DEFAULT 1,
    notes TEXT
);
```

---

## 9. Knowledge Graph Design

### Graph Purpose

The knowledge graph persists learned relationships so future transactions benefit from past analysis without re-running expensive inference. It answers queries like:

- "Who are all the merchants this user pays for subscriptions?"
- "What is the relationship between HDFC and this recurring transfer?"
- "Which transactions belong to the user's monthly SIP routine?"

### Node Types and Their `externalId`

| NodeType | `externalId` |
|----------|-------------|
| merchant | `merchants.id` (UUID) |
| person | `persons.id` (UUID) |
| transaction | `transactions.id` (UUID) |
| category | `CategoryTaxonomy` ID string |
| account | `Ledger.id` (UUID) |
| institution | Bank name string |
| recurringPattern | `recurring_patterns.id` (UUID) |

### Edge Semantics

| Edge | From | To | Meaning |
|------|------|----|---------|
| PAID_TO | transaction | merchant/person | User paid this entity |
| PAID_FROM | transaction | person/merchant | User received from this entity |
| BELONGS_TO | transaction | recurringPattern | Transaction is part of pattern |
| CLASSIFIED_AS | transaction/merchant | category | Classification applied |
| RECURS_WITH | merchant/person | recurringPattern | Entity is part of pattern |
| PAYS_RENT_TO | self (implicit) | person | Inferred rent relationship |
| PAYS_CARD_TO | self | merchant/institution | Credit card payoff |
| INVESTS_WITH | self | merchant | SIP/investment relation |
| RELATED_TO | person | person/merchant | Generic relation |

### Graph Algorithms

```
GraphAlgorithms implements:

1. BFS traversal (depth-limited to 3 hops for performance)
2. Weighted path scoring (weight × observationCount decay)
3. Community detection (for merchant clustering by category)
4. Entity disambiguation (fuzzy name → canonical node merge)
```

### GraphBuilder: Post-Import Update

After each statement import, `GraphBuilder` runs as a background task:

```
For each imported transaction:
  1. Ensure merchant/person node exists (upsert)
  2. Add PAID_TO or PAID_FROM edge (or increment weight)
  3. If recurring: add BELONGS_TO + RECURS_WITH edges
  4. If relationship inferred: add relationship edge
  5. Add CLASSIFIED_AS edge
```

---

## 10. CoreML Architecture

### Design Principle

CoreML models are the fallback layer, not the primary one. They activate only when deterministic stages fail to reach 0.80 confidence.

### Model 1: Merchant Classifier

- **Input:** Raw narration string (tokenized, cleaned)
- **Output:** Merchant ID or "unknown"
- **Architecture:** Create ML Text Classifier (n-gram TF-IDF + linear)
- **Training data:** All imported transaction narrations with confirmed merchant labels
- **Update trigger:** After 500+ new corrections since last training
- **Size target:** <5MB .mlpackage

### Model 2: Category Classifier

- **Input:** Merchant name, amount bucket, transaction type (debit/credit), ledger kind, day-of-month
- **Output:** CategoryTaxonomy ID
- **Architecture:** Create ML Tabular Classifier
- **Training data:** Transactions with confirmed categories (user corrections + rule-confirmed)
- **Feature importance:** Merchant > amount bucket > debit/credit > ledger kind

### Model 3: Relationship Classifier

- **Input:** Person name, average amount, frequency per month, days-after-salary, amount-is-round
- **Output:** RelationshipType
- **Architecture:** Create ML Tabular Classifier (small, <100KB)
- **Training signals:** Behavioral features only — no text
- **Classes:** landlord, friend, family, employer, loan_provider, reimbursement, unknown

### Model 4: Embedding Generator

- **Purpose:** Produce dense vector representations of narrations for fuzzy merchant matching
- **Architecture:** Sentence-level bag-of-words via `MLWordTagger` or manual TF-IDF
- **Output:** 64-dim Float32 vector per narration
- **Use:** Nearest-neighbor search against stored merchant embeddings
- **On-device:** Yes — no CoreML model file required; computed from alias frequency tables

### ModelManager

```swift
// FinanceIntelligence/MachineLearning/ModelManager.swift
public actor ModelManager {
    public func loadMerchantClassifier() async throws -> MerchantClassifierModel?
    public func loadCategoryClassifier() async throws -> CategoryClassifierModel?
    public func loadRelationshipClassifier() async throws -> RelationshipClassifierModel?
    public func isModelAvailable(_ name: String) -> Bool
    public func currentModelVersion(_ name: String) -> String?
}
```

Models load lazily on first use. Missing models fall back gracefully without error.

---

## 11. Merchant Intelligence

### Resolution Pipeline (4 Stages)

```
Raw Narration
     │
     ▼
Stage 1: MerchantTextCleaner
  - Strip processor prefixes (SQ*, TST*, PAYPAL*, UPI-, NEFT-, IMPS-)
  - Strip transaction IDs (UUIDs, 8+ digit sequences)
  - Strip UPI references (UPI-XXXXXXXXXX)
  - Strip city/state noise (MUMBAI MH, BANGALORE KA)
  - Strip trailing URLs
  - Output: cleaned string
     │
     ▼
Stage 2: AliasResolver (exact/substring match)
  - Check merchant_aliases table (300+ entries, cached in memory)
  - Confidence: 0.92
  - If hit: return MerchantCandidate with merchantId
     │
     ▼
Stage 3: EmbeddingIndex (fuzzy vector match)
  - Only runs if Stage 2 missed
  - Generate narration embedding (64-dim)
  - CosineSimilarity against top-1000 merchant embeddings in memory
  - Threshold: similarity > 0.80 → accept
  - Confidence: similarity score × 0.85
     │
     ▼
Stage 4: Fallback
  - Title-case cleaned string
  - Confidence: 0.50
```

### Alias Table Expansion Plan

Current: ~40 aliases.  
Target: 300+ covering:
- All major Indian UPI payees (Zepto, Swiggy, Zomato, BigBasket, Blinkit)
- All major credit card issuers (AMEX, HDFC, ICICI, SBI, Axis)
- Utility providers (BESCOM, TPDDL, MumbaiElectric)
- Streaming (Netflix, Spotify, JioSaavn, Disney+)
- Investment platforms (Zerodha, Groww, Kuvera, Coin)
- Insurance (LIC, HDFC Life, ICICI Pru, Max Life)

### UPI-Specific Resolution

UPI narrations have structure: `UPI-<NAME>-<UPIID>-<REF>`

```swift
// UPIDescriptionParser extracts:
struct UPIParsedResult {
    let payeeName: String     // "RITIK GUPTA"
    let upiHandle: String?    // "ritikgupta@upi"
    let referenceNumber: String?
}
```

UPI payee name → PersonResolver → Person entity  
UPI payee is merchant? → MerchantResolver → Merchant entity

---

## 12. Categorization & Intent Engine

### Rule Engine Design

Rules are evaluated in priority order. First match wins.

```swift
public struct Rule: Sendable {
    public let id: String
    public let priority: Int              // lower = higher priority
    public let condition: RuleCondition
    public let outcome: RuleOutcome
}

public enum RuleCondition: Sendable {
    case tokenContains([String])          // any token matches
    case tokenContainsAll([String])       // all tokens present
    case amountRange(ClosedRange<Int64>)  // amount in minor units
    case ledgerKind(LedgerKind)
    case hasIndicator(TransactionIndicator)
    case compound([RuleCondition], logic: Logic)
}

public struct RuleOutcome: Sendable {
    public let categoryId: String?
    public let intentId: String?
    public let confidence: Double
}
```

### Intent Rules (Key Examples)

| Pattern | Tokens / Signals | Intent |
|---------|-----------------|--------|
| Credit event, payroll indicator | `hasPayrollIndicator` + `.credit` | `.salary` |
| AMEX, HDFC CC, round amount | `["amex","american express"]` | `.creditCardPayment` |
| ACH NACH, SIP, Kuvera, Groww | `["sip","nach","kuvera","groww"]` | `.mutualFundSIP` |
| LIC, Max Life, HDFC Life | `["lic","max life","hdfc life"]` | `.insurance` |
| Netflix, Spotify, Jio | `["netflix","spotify","jio"]` | `.subscription` |
| ATM | `["atm","cash withdrawal"]` | `.cashWithdrawal` |
| Refund indicator | `hasRefundIndicator` | `.refund` |
| NEFT/IMPS to person | `hasTransferIndicator` + personResolved | `.transfer` |

### Category ↔ Intent Consistency

The engine enforces soft consistency rules:

```
creditCardPayment → category must be "fees" or "transfers"
mutualFundSIP     → category must be "transfers" or "investments"
salary            → category must be "income"
rent              → category must be "housing"
```

Violations are logged and flagged for review but not blocked.

---

## 13. Recurring Detection

### Detection Algorithm

```swift
public actor RecurringDetector {
    // Input: all transactions for a given merchant or person
    // Step 1: group by merchant/person
    // Step 2: compute inter-transaction intervals (days)
    // Step 3: cluster intervals using tolerance bands:
    //   weekly: 7 ± 3 days
    //   monthly: 30 ± 5 days
    //   quarterly: 90 ± 10 days
    //   yearly: 365 ± 15 days
    // Step 4: compute amount variance across cluster
    // Step 5: score = (interval_consistency × 0.5) + (amount_consistency × 0.3) + (occurrence_count_bonus × 0.2)
    // Threshold: score > 0.70 → recurring
}
```

### Confidence Scoring Factors

| Factor | Weight |
|--------|--------|
| Interval consistency (CV of intervals) | 50% |
| Amount consistency (CV of amounts) | 30% |
| Occurrence count (≥3: +0.1, ≥6: +0.2) | 20% |

### ScheduleInference

Predicts next expected transaction date:

```swift
// nextDate = lastObservedAt + medianInterval
// Provides: expectedDateRange = nextDate ± (intervalStdDev × 1.5)
// Used by: UI to show "Spotify due in 3 days"
```

---

## 14. Relationship Engine

### PersonResolver

Extracts person entities from:
1. UPI narrations (structured: name + UPI handle)
2. NEFT/IMPS narrations (name in description)
3. Cheque narrations

Deduplication: normalize name (uppercase, strip titles), match against `person_aliases`.

### RelationshipEngine Signals

Evaluated per person after accumulating ≥3 transactions:

```swift
func inferRelationship(for person: Person, transactions: [Transaction]) -> (RelationshipType, Double) {
    var signals: [RelationshipSignal: Double] = [:]

    // Signal: consistent monthly amount → rent/loan
    if hasConsistentMonthlyAmount(transactions) {
        signals[.recurringAmount] = 0.4
        if isRoundAmount(transactions) { signals[.roundNumber] = 0.2 }
    }

    // Signal: occurs 3-7 days after salary credit
    if occursPostSalary(transactions, salaryDay: salaryCycle?.averageDayOfMonth) {
        signals[.postSalaryTiming] = 0.3
    }

    // Signal: regular day-of-month (±2 days)
    if hasRegularDayOfMonth(transactions) {
        signals[.regularInterval] = 0.2
    }

    // Classify
    let score = signals.values.reduce(0, +)
    if score > 0.6 && signals[.recurringAmount] != nil { return (.landlord, score) }
    if signals[.postSalaryTiming] != nil && !isRoundAmount(transactions) { return (.friend, score * 0.7) }
    return (.unknown, score * 0.4)
}
```

### Relationship Confidence Update

Confidence increases with each new corroborating transaction:

```
newConfidence = min(1.0, oldConfidence + (0.05 × evidenceCount))
```

---

## 15. Behavior Intelligence

### SalaryAnalyzer

```swift
public actor SalaryAnalyzer {
    // Query: transactions WHERE transactionType = .credit
    //   AND (hasPayrollIndicator OR category = 'income.salary')
    //   ORDER BY postedAt
    // Group by month, find dominant credit per month
    // Compute: averageDayOfMonth, averageAmount, consistency
    // Output: SalaryCycle
}
```

### CashflowAnalyzer

Produces monthly cash flow timeline:

```swift
public struct MonthlySnapshot: Sendable {
    public let month: Date  // truncated to month
    public let totalDebitMinorUnits: Int64
    public let totalCreditMinorUnits: Int64
    public let netMinorUnits: Int64
    public let transactionCount: Int
    public let topCategories: [(categoryId: String, amount: Int64)]
}
```

### FinancialRoutineDetector

Detects user's monthly financial sequence:

```
Salary (day N)
  → Rent payment (day N+2 to N+5)
  → Credit card payment (day N+5 to N+10)
  → SIP contributions (day N+1 to N+7)
  → Insurance premiums (yearly, month M)
```

Routines are persisted as `BehaviorPattern` and used to:
- Predict upcoming transactions (cash flow forecast)
- Flag anomalies (salary late, rent missing)
- Generate behavior-based descriptions

---

## 16. Description Generation

### DescriptionContext

```swift
public struct DescriptionContext: Sendable {
    public let merchantName: String?
    public let personName: String?
    public let intent: TransactionIntent
    public let categoryId: String
    public let recurringCadence: RecurringCadence?
    public let relationship: RelationshipType?
    public let amount: Decimal
    public let currencyCode: String
    public let confidence: Double
}
```

### FallbackGenerator (Deterministic)

Template-based, always available:

```swift
// Examples:
// intent: .creditCardPayment, merchant: "American Express"
// → "American Express credit card payment"

// intent: .mutualFundSIP, merchant: "Groww"
// → "Monthly SIP via Groww"

// intent: .rent, person: "Ritik Gupta"
// → "Monthly rent — Ritik Gupta"

// intent: .subscription, merchant: "Netflix"
// → "Netflix subscription"
```

### AppleIntelligenceAdapter (iOS 18+)

```swift
// FinanceIntelligence/DescriptionGeneration/AppleIntelligenceAdapter.swift
@available(iOS 18.0, macOS 15.0, *)
public struct AppleIntelligenceAdapter: Sendable {
    // Uses Foundation Models framework
    // Input: DescriptionContext (structured data ONLY)
    // Output: natural language string
    // Guard: Apple Intelligence must never receive raw transaction data
    //        or make any financial classification decisions
    //
    // Prompt template (static, not user-configurable):
    // "Generate a short, natural description (under 8 words) for a financial
    //  transaction with these facts: [facts]. Do not add interpretation."
}
```

Apple Intelligence receives only the post-classification context. It never sees raw narrations.

---

## 17. Sequence Diagrams

### 17.1 Statement Import → Intelligence Enrichment

```
User          ImportView      ImportPipeline    Parser     Repository   IntelligencePipeline
  │                │                │              │             │               │
  │──import file──▶│                │              │             │               │
  │                │──parseFile()──▶│              │             │               │
  │                │                │──parse()────▶│             │               │
  │                │                │◀─ParsedTxns─-│             │               │
  │                │                │──dedup()────▶│             │               │
  │                │                │──saveBatch()▶│             │               │
  │                │                │              │             │               │
  │                │                │──enrichBatch()─────────────────────────────▶│
  │                │                │              │             │     (per txn) │
  │                │                │              │             │   extract()   │
  │                │                │              │             │   resolveEntities()
  │                │                │              │             │   queryHistory()
  │                │                │              │             │   queryGraph()
  │                │                │              │             │   fuseSignals()
  │                │                │              │             │   generateDesc()
  │                │                │◀──[EnrichedTransaction]────────────────────│
  │                │                │──updateGraph()────────────▶│               │
  │                │                │──detectRecurring()─────────▶│               │
  │                │◀──ImportResult─│              │             │               │
  │◀──show results─│                │              │             │               │
```

### 17.2 Single Transaction Analysis

```
Caller                IntelligencePipeline           GraphStore      CoreML
  │                          │                           │              │
  │──analyze(txn, ctx)───────▶│                          │              │
  │                          │──extractFeatures()        │              │
  │                          │──applyRules()             │              │
  │                          │  if conf < 0.8:           │              │
  │                          │──resolveEntities()        │              │
  │                          │──queryHistory()           │              │
  │                          │──fetchGraphSignal()──────▶│              │
  │                          │◀─GraphSignal──────────────│              │
  │                          │  if still conf < 0.8:     │              │
  │                          │──predictCategory()────────────────────────▶│
  │                          │◀─MLPrediction─────────────────────────────│
  │                          │──fuseSignals()            │              │
  │                          │──generateDescription()    │              │
  │◀─EnrichedTransaction──────│                          │              │
```

### 17.3 User Correction → Learning Loop

```
User         TransactionDetailVM    IntelligenceService    CorrectionStore   GraphStore
  │                   │                    │                     │               │
  │──correct cat──────▶│                   │                     │               │
  │                   │──learn(txn, cat)──▶│                     │               │
  │                   │                    │──storeCorrection()──▶│               │
  │                   │                    │──updateLocalLearner()│               │
  │                   │                    │──updateGraphEdge()───────────────────▶│
  │                   │                    │──checkRetrainThreshold()             │
  │                   │◀──success──────────│                     │               │
  │◀──UI updated──────│                    │                     │               │
```

---

## 18. Testing Strategy

### Test Pyramid

```
         ╱─────────────────╲
        ╱  Integration Tests ╲   — 20 tests
       ╱    (actor + GRDB)    ╲
      ╱────────────────────────╲
     ╱    Component Tests       ╲  — 80 tests
    ╱   (pipeline stages, rules) ╲
   ╱─────────────────────────────╲
  ╱        Unit Tests             ╲ — 200+ tests
 ╱  (resolvers, normalizers, algo) ╲
╱───────────────────────────────────╲
```

### Unit Test Coverage Requirements

| Component | Required Coverage |
|-----------|-----------------|
| RuleEngine | 100% — every rule has input/output test |
| MerchantTextCleaner | 100% — every pattern has test case |
| UPIDescriptionParser | 100% |
| RecurringDetector algorithm | 95% |
| RelationshipEngine signals | 90% |
| SignalFuser | 90% |
| FallbackGenerator | 100% — every intent/template |

### Golden Transaction Tests

Maintain a fixture file of 100 real anonymized narrations with expected outputs:

```swift
// FinanceTesting/Fixtures/IntelligenceFixtures.swift
struct IntelligenceFixture {
    let rawNarration: String
    let expectedMerchant: String
    let expectedCategory: String
    let expectedIntent: String
    let minimumConfidence: Double
}

// Examples:
IntelligenceFixture(
    rawNarration: "UPI-AMERICAN EXPRESS-AEBC373008620701005-123456789",
    expectedMerchant: "American Express",
    expectedCategory: "fees",
    expectedIntent: "credit_card_payment",
    minimumConfidence: 0.90
)
```

### Performance Tests

```swift
// XCTest measure blocks:
func testBatchAnalysis_1000transactions_under2seconds() {
    measure { try await pipeline.analyzeBatch(fixture.transactions1000, context: .empty) }
}

func testMerchantResolution_underOneMillisecond() {
    measure { resolver.resolve("UPI-AMERICAN EXPRESS-AEBC373") }
}

func testGraphQuery_depth2_under10ms() {
    measure { graphStore.fetchNeighbors(nodeId: merchantNode.id, depth: 2) }
}
```

---

## 19. Migration Strategy

### Phase 0 (Prerequisite): Database Migration

Add intelligence columns to `transactions` table and create all new tables via `AppMigration`.

**Risk:** Low — only adds columns with nullable defaults.  
**Rollback:** Drop new tables (no data loss on existing transactions).

### Phase 1: Rule Engine Replacement

Replace `RuleBasedCategorizer` with new `RuleEngine` (intent + category). Keep `TransactionIntelligenceService` protocol unchanged.

**Risk:** Medium — verify accuracy parity on existing test fixtures before shipping.  
**Gate:** Golden test suite must pass at ≥ current accuracy.

### Phase 2: Entity Resolution

Ship `MerchantResolver` (expanded alias table + embedding index) and `PersonResolver`.  
**Scope:** Changes `MerchantCandidate` resolution only — existing API unchanged.

### Phase 3: Persistence Layer

Ship `Persistence/` — repositories + GRDB models. Run `GraphBuilder` on first launch for existing transactions (background task, progress tracked).

**Risk:** First-launch migration on large datasets (100k txns). Use async chunked processing.

### Phase 4: Knowledge Graph + Recurring + Relationships

Ship `KnowledgeGraph/`, `Recurring/`, `Relationships/`. These are additive — no existing behavior changes.

### Phase 5: Behavior + Description Generation

Ship `Behavior/` and `DescriptionGeneration/`. Apple Intelligence adapter behind `#available(iOS 18.0, *)`.

### Phase 6: CoreML Integration

Ship trained models. Gate behind `ModelManager.isModelAvailable()` — zero impact if models absent.

---

## 20. Performance Strategy

### Latency Budgets

| Operation | Target |
|-----------|--------|
| Single transaction enrichment | < 10ms |
| Batch of 500 transactions | < 2s |
| Merchant alias lookup (memory) | < 0.1ms |
| Graph query (depth 2) | < 10ms |
| Recurring detection (100 txns) | < 50ms |
| Embedding nearest-neighbor (memory, 10k merchants) | < 5ms |

### Memory Caches

```swift
// Actor-isolated, lazy-loaded on first use:
actor MerchantAliasCache {
    // All merchant_aliases loaded into memory at startup: ~2MB for 300 entries
    // Invalidated on alias table write
}

actor EmbeddingCache {
    // Top-1000 merchant embeddings in memory: ~32KB at 64-dim Float32
    // Full 10k merchants: ~2.5MB — acceptable, load fully at startup
}
```

### Graph Query Optimization

- Depth-1 queries (direct neighbors): indexed lookup, <1ms
- Depth-2 queries: two indexed lookups + join, <10ms
- Depth-3+: only for explicit relationship traversal; batch offline

### SQLite Index Strategy

All foreign keys indexed. All `postedAt`, `categoryId`, `merchantId`, `personId` columns indexed. Compound index on `(ledgerId, postedAt DESC)` for timeline queries.

### Batch Import Optimization

```swift
// Process in structured concurrency task groups
// Chunk size: 50 transactions per child task
// Stage 5 (CoreML): batched model inference if model supports batching
// Graph updates: deferred, runs after import completes
```

---

## 21. Incremental Learning Strategy

### How the System Gets Smarter

Every imported statement contributes to 4 learning loops:

**Loop 1: Alias Expansion**  
When a user corrects a merchant name, the corrected name + raw narration becomes a new alias entry. Subsequent narrations with the same pattern resolve correctly.

**Loop 2: Recurring Pattern Growth**  
Each new matching transaction increments `occurrenceCount` and updates `averageAmountMinorUnits`. Confidence increases monotonically.

**Loop 3: Graph Edge Strengthening**  
Each observed transaction increments `observationCount` on its graph edges. Stronger edges influence signal fusion weight.

**Loop 4: CoreML Retraining**  
Triggered when: `correctionCount ≥ 500` since last training. Exports anonymized correction data as CSV. Training runs via Create ML or PyTorch pipeline. New model version replaces old via `ModelManager`.

### Training Data Generation

```swift
public actor TrainingDataExporter {
    // Exports corrections eligible for training:
    //   - User corrections with known category + merchant
    //   - Rule-confirmed classifications with confidence ≥ 0.95
    //   - Historical matches with confidence ≥ 0.90
    // Format: CSV matching existing training schema
    // Privacy: never export person names (use personId hashes only)
}
```

### Retraining Trigger Logic

```
correctionStore.totalEligibleCorrections() ≥ 500
  AND daysSinceLastTraining ≥ 30
  AND userHasGrantedMLPermission   ← explicit opt-in
→ background retraining job
```

---

## 22. Apple Intelligence Integration

### Strict Boundaries

Apple Intelligence (Foundation Models, iOS 18+) is **only** used for natural language generation, never classification.

```
ALLOWED:
  - Convert DescriptionContext → human-readable string
  - Summarize monthly spending in conversational language
  - Format insight notifications

NOT ALLOWED:
  - Classify transaction category
  - Infer merchant name
  - Determine if recurring
  - Make any financial inference
```

### Integration Pattern

```swift
@available(iOS 18.0, macOS 15.0, *)
public struct AppleIntelligenceAdapter: Sendable {
    private let session: LanguageModelSession  // Foundation Models

    public func generateDescription(from context: DescriptionContext) async throws -> String {
        // Build a tightly-constrained prompt from structured context only
        let prompt = buildPrompt(context)
        let response = try await session.respond(to: prompt)
        return sanitize(response.content)  // strip any financial inference
    }

    private func buildPrompt(_ ctx: DescriptionContext) -> String {
        // Strictly factual — no open-ended generation
        // Example: "Summarize in 6 words: paid to [merchant], [intent], monthly"
    }
}
```

### Graceful Degradation

If Apple Intelligence unavailable (iOS < 18, opt-out, no entitlement):  
→ `FallbackGenerator` produces deterministic template string.  
→ Zero user-visible difference in functionality.

---

## 23. Risk Analysis

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| CoreML model absent at runtime | High | Low | ModelManager graceful fallback |
| Graph grows unbounded | Low | Medium | Max 1M nodes enforced; archive old transactions |
| Embedding memory pressure | Low | Medium | Lazy load, evict least-recently-used |
| SQLite lock contention during batch import | Medium | Medium | GRDB WAL mode; separate read/write queues |
| First-launch graph migration timeout | Medium | High | Chunked async processing; progress observable |
| Apple Intelligence API breaking change | Medium | Low | Behind availability check; fallback always ready |
| Person deduplication failures | High | Medium | Conservative merge (require ≥2 signals to merge) |

### Privacy Risks

| Risk | Mitigation |
|------|-----------|
| Person names in logs | Logger redacts PII; no person names in log output |
| Training data export leaks PII | Export replaces person names with hashed IDs |
| Apple Intelligence sees raw transactions | Hard boundary: only DescriptionContext struct passed |
| Corrections file accessible to other apps | Stored in app sandbox; not in shared container |

### Accuracy Risks

| Risk | Mitigation |
|------|-----------|
| Alias table stale (new merchants) | User correction → auto-alias; quarterly alias table updates |
| Relationship misclassification | Low confidence → "unknown"; user confirmation before persisting |
| Recurring false positive | Require ≥3 occurrences; high amount variance → not recurring |
| Salary mis-detection | Require credit + payroll indicator + amount consistency |

---

## 24. Implementation Roadmap

### Phase 1 — Foundation (Weeks 1–3)

**Goal:** Replace rule engine; add intent taxonomy; no GRDB changes.

- [ ] `IntentTaxonomy.swift` — 20 intents
- [ ] `RuleEngine.swift` — ordered rule evaluation, intent output
- [ ] `IntentPrediction` in `EnrichedTransaction`
- [ ] `RuleLoader.swift` — load rules from JSON bundle (easier to update)
- [ ] Update `TransactionIntelligenceServiceImpl` to run RuleEngine
- [ ] 100% rule coverage in unit tests
- [ ] Golden fixture tests: 100 narrations

**Exit Criteria:** Golden tests ≥ 85% pass rate. No regression on existing tests.

---

### Phase 2 — Entity Resolution (Weeks 3–5)

**Goal:** Merchant alias table to 300+; UPI person extraction.

- [ ] Expand `merchant_aliases.json` (Indian + global merchants)
- [ ] `AliasResolver.swift` — exact + substring match
- [ ] `PersonResolver.swift` — UPI + NEFT/IMPS name extraction
- [ ] `PersonEntityStore.swift` — in-memory dedup + normalization
- [ ] `ResolvedEntities.swift` domain type
- [ ] Test: 50 UPI narrations → correct person extraction

**Exit Criteria:** Merchant resolution accuracy ≥ 80% on golden set.

---

### Phase 3 — Persistence (Weeks 5–7)

**Goal:** All intelligence entities persisted; graph structure in SQLite.

- [ ] Database migration: `merchants`, `merchant_aliases`, `persons`, `person_aliases` tables
- [ ] Database migration: `knowledge_graph_nodes`, `knowledge_graph_edges`, `embeddings`
- [ ] Database migration: `recurring_patterns`, `relationships`
- [ ] Database migration: transaction columns (`intentId`, `resolvedPersonId`, etc.)
- [ ] GRDB model types for all new tables
- [ ] Repository implementations (GRDB)
- [ ] `AppContainer` dependency injection for new repositories
- [ ] Integration tests for all repositories

**Exit Criteria:** All new tables created cleanly; repositories pass integration tests.

---

### Phase 4 — Knowledge Graph (Weeks 7–9)

**Goal:** Graph builds and queries correctly; boosts signal fusion.

- [ ] `GraphNode.swift`, `GraphEdge.swift`
- [ ] `GraphRepository.swift` + `GRDBGraphRepository.swift`
- [ ] `GraphBuilder.swift` — post-import graph update
- [ ] `GraphQueries.swift` — entity neighbors, path queries
- [ ] `GraphStore.swift` actor — orchestrates queries
- [ ] Signal fusion: graph signal contributes 0.85 weight
- [ ] Integration test: import 50 transactions → expected graph topology

**Exit Criteria:** Graph queries complete in <10ms at depth 2 on 1000-node graph.

---

### Phase 5 — Recurring & Relationships (Weeks 9–12)

**Goal:** Detect subscriptions, rent, SIPs automatically.

- [ ] `RecurringDetector.swift` — interval clustering algorithm
- [ ] `PatternAnalyzer.swift` — cadence inference
- [ ] `ScheduleInference.swift` — next-date prediction
- [ ] `RelationshipEngine.swift` — 5 behavioral signals
- [ ] `RelationshipClassifier.swift` — heuristic classifier
- [ ] `RecurringPatternRepository` + `RelationshipRepository`
- [ ] Test: Spotify 12× monthly → recurring detected at confidence ≥ 0.85
- [ ] Test: ₹22,000 monthly to same person → landlord at confidence ≥ 0.70

**Exit Criteria:** Recurring detection precision ≥ 0.90 (no false positives on fixture set).

---

### Phase 6 — Behavior Intelligence (Weeks 12–14)

**Goal:** Salary cycle + cash flow timeline + financial routine detection.

- [ ] `SalaryAnalyzer.swift` — monthly credit pattern
- [ ] `CashflowAnalyzer.swift` — monthly snapshot
- [ ] `FinancialRoutineDetector.swift` — salary→rent→CC→SIP sequence
- [ ] `BehaviorPattern` persistence
- [ ] `BehaviorPattern` surfaced via `TransactionIntelligenceService`

**Exit Criteria:** Salary cycle detected correctly on 6-month fixture dataset.

---

### Phase 7 — Description Generation (Weeks 14–16)

**Goal:** Human-readable descriptions for all transactions.

- [ ] `DescriptionContext.swift`
- [ ] `FallbackGenerator.swift` — template strings for all 20 intents
- [ ] `AppleIntelligenceAdapter.swift` — Foundation Models integration
- [ ] `DescriptionGenerator.swift` — routes to adapter or fallback
- [ ] UI: show `humanDescription` in transaction list
- [ ] Test: every intent produces valid fallback string

**Exit Criteria:** All transactions have non-empty descriptions. Apple Intelligence adapter compiles behind `#available(iOS 18.0, *)`.

---

### Phase 8 — CoreML + Incremental Learning (Weeks 16–20)

**Goal:** CoreML models trained and integrated; retraining pipeline operational.

- [ ] `ModelManager.swift` — lazy model loading
- [ ] `MerchantClassifier.swift` — CoreML text classifier
- [ ] `CategoryClassifier.swift` — CoreML tabular classifier
- [ ] `RelationshipClassifier.swift` — CoreML tabular classifier
- [ ] `EmbeddingGenerator.swift` — on-device 64-dim vectors
- [ ] `EmbeddingIndex.swift` — cosine similarity search
- [ ] `TrainingDataExporter.swift` — corrections → anonymized CSV
- [ ] Makefile target: `make intelligence-train` → PyTorch or CreateML pipeline
- [ ] Model version management in `intelligence_model_metadata` table

**Exit Criteria:** Full pipeline accuracy ≥ 90% on 100-narration golden test set. CoreML absent → graceful fallback, no crash.

---

### Summary Timeline

| Phase | Weeks | Focus |
|-------|-------|-------|
| 1 | 1–3 | Rule Engine + Intent Taxonomy |
| 2 | 3–5 | Entity Resolution (300+ aliases) |
| 3 | 5–7 | Persistence Layer (GRDB) |
| 4 | 7–9 | Knowledge Graph |
| 5 | 9–12 | Recurring + Relationships |
| 6 | 12–14 | Behavior Intelligence |
| 7 | 14–16 | Description Generation |
| 8 | 16–20 | CoreML + Learning Pipeline |

**Total:** ~20 weeks to full platform. Phases 1–4 alone deliver 85%+ accuracy on deterministic intelligence. Phases 5–8 close the remaining gap and add production-grade features.

---

*End of Architecture Document*
