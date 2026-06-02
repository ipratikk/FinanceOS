---
doc: 004-data-models
version: 0.1.0
status: Draft
date: 2026-06-02
---

# Data Models — FinanceIntelligence Platform

## Purpose

Define every Swift data model (structs, enums, protocols) required by the FinanceIntelligence platform. These models live in `FinanceIntelligence/Models/` and serve as the shared vocabulary between all intelligence modules. Models defined here must not import GRDB, SwiftUI, or any UI framework.

---

## Model Taxonomy

| Category | Models |
|---|---|
| Input models | `CategoryInput`, `IntentInput`, `IncomeInput`, `DescriptionInput`, `InsightContext`, `SubscriptionInput` |
| Prediction models | `MerchantPrediction`, `CategoryPrediction`, `IntentPrediction`, `IncomePrediction`, `RecurringPrediction`, `SubscriptionPrediction`, `AnomalySignal`, `LinkPrediction`, `EmbeddingVector` |
| Aggregate models | `TransactionIntelligence`, `EnrichedTransaction`, `FinancialInsight` |
| Infrastructure models | `ModelVersion`, `ModelName`, `IntelligenceEvent`, `UserCorrection`, `UserHistory` |
| Feature models | `TransactionFeatures`, `EntityID`, `UserFeedback` |

---

## Enumerations

### TransactionCategory

```swift
public enum TransactionCategory: String, Codable, CaseIterable {
    // Spending
    case food
    case groceries
    case dining
    case travel
    case fuel
    case shopping
    case entertainment
    case utilities
    case healthcare
    case education
    case personalCare

    // Financial obligations
    case rent
    case insurance
    case loanPayment
    case creditCardPayment
    case subscription

    // Transfers
    case peerTransfer
    case selfTransfer
    case investments
    case savingsDeposit

    // Income
    case salary
    case freelance
    case rental
    case dividend
    case refund
    case cashback

    // Other
    case fees
    case taxes
    case other

    public var subcategories: [TransactionSubcategory] { ... }
}
```

### TransactionSubcategory

```swift
public enum TransactionSubcategory: String, Codable {
    // Food
    case restaurant, cafeteria, fastFood, delivery, bakery

    // Travel
    case flight, hotel, train, bus, cab, metro, toll, parking

    // Shopping
    case electronics, clothing, furniture, books, sports, beauty, gifting

    // Utilities
    case electricity, water, internet, mobile, gas, broadband

    // Healthcare
    case pharmacy, hospitalFee, diagnostics, dentalCare, opticalCare

    // Financial
    case mutualFund, stockBroker, nps, ppf, gold, crypto, fixedDeposit

    // Subscriptions
    case streaming, software, news, gaming, fitness

    case other
}
```

### TransactionIntent

```swift
public enum TransactionIntent: String, Codable, CaseIterable {
    case salary
    case rent
    case creditCardPayment
    case loanPayment
    case investment
    case insurance
    case subscription
    case refund
    case cashback
    case incomeTransfer
    case peerPayment
    case grocery
    case food
    case fuel
    case travel
    case utilities
    case education
    case healthcare
    case shopping
    case entertainment
    case withdrawal
    case fee
    case tax
    case donation
    case unknown
}
```

### IncomeType

```swift
public enum IncomeType: String, Codable, CaseIterable {
    case salary
    case bonus
    case freelance
    case rental
    case dividend
    case interest
    case mutualFundRedemption
    case stockSale
    case refund
    case cashback
    case reimbursement
    case gift
    case otherIncome
}
```

### RecurringCadence

```swift
public enum RecurringCadence: String, Codable {
    case daily
    case weekly
    case biweekly
    case monthly
    case quarterly
    case biannual
    case annual
    case irregular
}
```

### AnomalyType

```swift
public enum AnomalyType: String, Codable {
    case unusuallyLargeAmount
    case unusuallySmallAmount
    case newMerchantInCategory
    case categorySpike
    case merchantSpike
    case duplicateSuspected
    case recurringAmountChanged
    case unexpectedFee
    case offHoursTransaction
}
```

### PredictionSource

```swift
public enum PredictionSource: String, Codable {
    case model           // base CoreML model
    case personalized    // PersonalizedClassifier kNN override
    case ruleEngine      // structural rule (structural tasks only)
    case fallback        // default when model unavailable
}
```

---

## Input Models

### CategoryInput

```swift
public struct CategoryInput: Sendable {
    public let narration: String
    public let amount: Decimal
    public let direction: TransactionDirection   // credit / debit
    public let merchantName: String?             // from Model 1 output
    public let paymentChannel: PaymentChannel?
    public let upiVPA: String?
}
```

### IntentInput

```swift
public struct IntentInput: Sendable {
    public let narration: String
    public let amount: Decimal
    public let direction: TransactionDirection
    public let category: TransactionCategory?    // from Model 2 output
    public let merchantName: String?
    public let paymentChannel: PaymentChannel?
}
```

### IncomeInput

```swift
public struct IncomeInput: Sendable {
    public let narration: String
    public let amount: Decimal
    public let direction: TransactionDirection   // must be .credit
    public let paymentChannel: PaymentChannel?
    public let referenceID: String?
}
```

### DescriptionInput

```swift
public struct DescriptionInput: Sendable {
    public let narration: String
    public let merchantName: String?
    public let category: TransactionCategory?
    public let subcategory: TransactionSubcategory?
    public let intent: TransactionIntent?
    public let amount: Decimal
    public let direction: TransactionDirection
    public let date: Date
    public let paymentChannel: PaymentChannel?
}
```

### InsightContext

```swift
public struct InsightContext: Sendable {
    public let periodStart: Date
    public let periodEnd: Date
    public let totalSpend: Decimal
    public let totalIncome: Decimal
    public let spendByCategory: [TransactionCategory: Decimal]
    public let topMerchants: [MerchantSpend]
    public let recurringCommitments: [RecurringItem]
    public let anomalies: [AnomalySignal]
    public let priorPeriodTotalSpend: Decimal?
    public let userCurrency: String
}
```

---

## Prediction Models

### MerchantPrediction

```swift
public struct MerchantPrediction: Sendable {
    public let canonicalName: String
    public let confidence: Float
    public let source: PredictionSource
    public let alternatives: [MerchantCandidate]   // top-3

    public struct MerchantCandidate: Sendable {
        public let name: String
        public let confidence: Float
    }
}
```

### CategoryPrediction

```swift
public struct CategoryPrediction: Sendable {
    public let category: TransactionCategory
    public let subcategory: TransactionSubcategory?
    public let confidence: Float
    public let source: PredictionSource
    public let topAlternatives: [CategoryCandidate]

    public struct CategoryCandidate: Sendable {
        public let category: TransactionCategory
        public let confidence: Float
    }
}
```

### IntentPrediction

```swift
public struct IntentPrediction: Sendable {
    public let intent: TransactionIntent
    public let confidence: Float
    public let source: PredictionSource
}
```

### IncomePrediction

```swift
public struct IncomePrediction: Sendable {
    public let isIncome: Bool
    public let incomeType: IncomeType?
    public let confidence: Float
    public let source: PredictionSource
}
```

### EmbeddingVector

```swift
public struct EmbeddingVector: Sendable {
    public let values: [Float]        // Float32[128]
    public let modelVersion: String
    public let generatedAt: Date
}
```

### RecurringPrediction

```swift
public struct RecurringPrediction: Sendable {
    public let isRecurring: Bool
    public let cadence: RecurringCadence?
    public let confidence: Float
    public let nextExpectedDate: Date?
    public let expectedAmountRange: ClosedRange<Decimal>?
}
```

### SubscriptionPrediction

```swift
public struct SubscriptionPrediction: Sendable {
    public let isSubscription: Bool
    public let confidence: Float
    public let serviceName: String?    // canonical subscription service
    public let billingCycle: RecurringCadence?
}
```

### AnomalySignal

```swift
public struct AnomalySignal: Sendable {
    public let type: AnomalyType
    public let severity: AnomalySeverity   // low, medium, high, critical
    public let confidence: Float
    public let description: String
    public let baselineValue: Decimal?
    public let observedValue: Decimal?
}

public enum AnomalySeverity: String, Codable {
    case low, medium, high, critical
}
```

### LinkPrediction

```swift
public struct LinkPrediction: Sendable {
    public let sourceEntityID: EntityID
    public let targetEntityID: EntityID
    public let relationshipType: RelationshipType
    public let confidence: Float
}
```

---

## Aggregate Models

### TransactionIntelligence

The unified output of the ML inference pipeline (Layers 2–3).

```swift
public struct TransactionIntelligence: Sendable {
    public let transactionID: TransactionID
    public let merchant: MerchantPrediction?
    public let category: CategoryPrediction
    public let intent: IntentPrediction?
    public let income: IncomePrediction?
    public let embedding: EmbeddingVector?
    public let recurring: RecurringPrediction?
    public let subscription: SubscriptionPrediction?
    public let anomalies: [AnomalySignal]
    public let description: String?
    public let pipelineLatencyMs: Double
    public let modelVersions: [String: String]   // modelName → version
}
```

### FinancialInsight

```swift
public struct FinancialInsight: Sendable, Identifiable {
    public let id: UUID
    public let type: InsightType
    public let title: String
    public let narrative: String
    public let supportingData: InsightData?
    public let confidence: Float
    public let generatedAt: Date
    public let period: DateInterval

    public enum InsightType: String, Codable {
        case spendingTrend
        case categoryAnomaly
        case recurringCommitment
        case cashflowSummary
        case merchantPatern
        case savingsOpportunity
        case subscriptionAlert
        case incomePattern
    }
}
```

---

## Infrastructure Models

### ModelName

```swift
public struct ModelName: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public static let merchant     = ModelName("merchant_recognizer")
    public static let category     = ModelName("category_classifier")
    public static let intent       = ModelName("intent_classifier")
    public static let income       = ModelName("income_classifier")
    public static let embedding    = ModelName("embedding_encoder")
    public static let recurring    = ModelName("recurring_detector")
    public static let anomaly      = ModelName("anomaly_detector")
    public static let linkPredict  = ModelName("link_predictor")
}
```

### ModelVersion

```swift
public struct ModelVersion: Sendable, Equatable {
    public let name: String
    public let version: String          // semver: "1.2.0"
    public let datasetVersion: String   // "2026-05-01"
    public let artifactHash: String     // SHA256 of .mlpackage
    public let minAppVersion: String
}
```

### TransactionFeatures

Feature vector passed to tabular models (Recurring, Anomaly).

```swift
public struct TransactionFeatures: Sendable {
    public let amount: Decimal
    public let direction: TransactionDirection
    public let dayOfMonth: Int
    public let dayOfWeek: Int
    public let hourOfDay: Int
    public let paymentChannel: PaymentChannel
    public let merchantCategory: TransactionCategory?
    public let amountRoundness: Float   // 0 = exact, 1 = round number
    public let narrationLength: Int
    public let hasUPIRef: Bool
    public let hasIFSC: Bool
}
```

### UserHistory

Statistical baseline for anomaly detection.

```swift
public struct UserHistory: Sendable {
    public let merchantAmountStats: [String: AmountStats]    // merchant → stats
    public let categoryMonthlyStats: [TransactionCategory: AmountStats]
    public let transactionCount: Int
    public let historyWindowDays: Int
}

public struct AmountStats: Sendable {
    public let mean: Decimal
    public let standardDeviation: Decimal
    public let p25: Decimal
    public let p75: Decimal
    public let max: Decimal
}
```

---

## GRDB Schema Extensions

New tables required by the intelligence platform:

```sql
-- Transaction embeddings (indexed for ANN search)
CREATE TABLE transaction_embeddings (
    transaction_id TEXT NOT NULL REFERENCES transactions(id),
    model_version  TEXT NOT NULL,
    values         BLOB NOT NULL,   -- Float32 array, little-endian
    generated_at   DATETIME NOT NULL,
    PRIMARY KEY (transaction_id, model_version)
);

-- Intelligence predictions (audit trail)
CREATE TABLE transaction_intelligence (
    transaction_id       TEXT PRIMARY KEY REFERENCES transactions(id),
    merchant_name        TEXT,
    merchant_confidence  REAL,
    category             TEXT NOT NULL,
    subcategory          TEXT,
    category_confidence  REAL NOT NULL,
    intent               TEXT,
    intent_confidence    REAL,
    is_income            INTEGER,
    income_type          TEXT,
    is_recurring         INTEGER,
    recurring_cadence    TEXT,
    is_subscription      INTEGER,
    anomaly_count        INTEGER DEFAULT 0,
    description          TEXT,
    pipeline_latency_ms  REAL,
    model_versions       TEXT,   -- JSON
    created_at           DATETIME NOT NULL,
    updated_at           DATETIME NOT NULL
);

-- Anomaly signals
CREATE TABLE anomaly_signals (
    id             TEXT PRIMARY KEY,
    transaction_id TEXT NOT NULL REFERENCES transactions(id),
    type           TEXT NOT NULL,
    severity       TEXT NOT NULL,
    confidence     REAL NOT NULL,
    description    TEXT NOT NULL,
    baseline_value REAL,
    observed_value REAL,
    created_at     DATETIME NOT NULL
);
```

---

## Risks

| Risk | Mitigation |
|---|---|
| Confidence score calibration varies per model | Apply temperature scaling post-training; document calibration per model |
| EmbeddingVector size growth with transaction history | Limit stored embeddings to last 12 months; prune on import |
| TransactionFeatures missing fields on older bank formats | Use Optional fields; tabular model trained with missingness |
| ModelVersion hash mismatch detection timing | Validate on registry load, not on inference call |
