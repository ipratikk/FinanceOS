---
doc: 019-insight-generation
version: 0.1.0
status: Draft
date: 2026-06-02
---

# 019 — Financial Insight Generation

## Purpose

This document specifies the design for the financial insight generation subsystem. The subsystem consumes structured, aggregated transaction data from GRDB and produces natural-language insights via an on-device local LLM. Insights are classified into seven types and are surfaced to the user through the FinanceUI layer.

All inference runs on-device. No transaction data, prompt content, or generated text leaves the device.

---

## Architecture

```
GRDB (SQLite)
    │
    ▼
InsightDataAggregator
    │  (aggregates by category, merchant, time period)
    ▼
InsightContext  ← structured JSON snapshot of financial period
    │
    ▼
PromptBuilder
    │  (injects system persona + structured context + instruction)
    ▼
LLMProvider  (MLX on Mac / CoreML on iPhone)
    │
    ▼
RawLLMOutput  (structured JSON string)
    │
    ▼
InsightParser  (decodes JSON → InsightResult)
    │
    ▼
InsightStore  (persisted via GRDB)
    │
    ▼
InsightRepository (protocol)  ← consumed by ViewModel
```

### Batching Flow

```
InsightBatchRequest
    ├── insight_types: [monthly_summary, spending_analysis, ...]
    └── period: DateInterval

        ↓

InsightDataAggregator
    ├── queryTransactions(period:)
    ├── aggregateByCategory()
    ├── aggregateByMerchant()
    └── computeCashFlowMetrics()

        ↓

PromptBuilder.buildBatchPrompt(context:, types:)
    → single LLM call requesting all types in one structured response

        ↓

LLM → JSON array of InsightResult

        ↓

InsightParser.parseBatch(_:) → [InsightResult]
```

---

## Inputs

| Input | Type | Source |
|---|---|---|
| Date period | `DateInterval` | Caller (ViewModel) |
| Requested insight types | `[InsightType]` | Caller or default full set |
| Transaction rows | GRDB query result | `TransactionRepository` |
| Category aggregates | `[CategoryAggregate]` | `InsightDataAggregator` |
| Merchant aggregates | `[MerchantAggregate]` | `InsightDataAggregator` |
| Prior month comparison | optional `[CategoryAggregate]` | `InsightDataAggregator` |
| Cached insights | `[InsightResult]` | `InsightStore` (cache hit path) |

### InsightContext JSON Structure

```json
{
  "period": { "start": "2026-05-01", "end": "2026-05-31" },
  "total_income": 125000.00,
  "total_expenses": 84320.50,
  "net_cashflow": 40679.50,
  "categories": [
    { "name": "Food & Dining", "amount": 12450.00, "count": 34,
      "mom_change_pct": 8.2, "top_merchants": ["Swiggy", "Zomato"] },
    { "name": "Utilities", "amount": 3200.00, "count": 4,
      "mom_change_pct": -2.1, "top_merchants": ["BESCOM", "Airtel"] }
  ],
  "recurring_commitments": [
    { "merchant": "Netflix", "amount": 649.00, "frequency": "monthly" },
    { "merchant": "Spotify", "amount": 119.00, "frequency": "monthly" }
  ],
  "unusual_transactions": [
    { "merchant": "Amazon", "amount": 34999.00,
      "reason": "3x above 90-day average spend" }
  ],
  "savings_rate_pct": 32.5
}
```

---

## Outputs

### InsightType Enum

```swift
public enum InsightType: String, Codable, CaseIterable {
    case monthlySummary          = "monthly_summary"
    case spendingAnalysis        = "spending_analysis"
    case recurringCommitments    = "recurring_commitments"
    case categoryTrends          = "category_trends"
    case cashFlowAnalysis        = "cash_flow_analysis"
    case unusualActivitySummary  = "unusual_activity_summary"
    case savingsOpportunity      = "savings_opportunity"
}
```

### InsightResult Structure

```swift
public struct InsightResult: Codable, Identifiable, Sendable {
    public let id: UUID
    public let type: InsightType
    public let headline: String          // max 80 chars, display-ready
    public let body: String              // 2-4 sentences
    public let supportingData: [SupportingDataPoint]
    public let confidence: Float         // 0.0 – 1.0
    public let generatedAt: Date
    public let periodStart: Date
    public let periodEnd: Date
}

public struct SupportingDataPoint: Codable, Sendable {
    public let label: String
    public let value: String             // pre-formatted: "₹12,450" or "+8.2%"
    public let trend: TrendDirection?
}

public enum TrendDirection: String, Codable, Sendable {
    case up, down, flat
}
```

### LLM Output JSON Schema (one insight)

```json
{
  "type": "spending_analysis",
  "headline": "Food spending rose 8% this month",
  "body": "You spent ₹12,450 on Food & Dining in May, up ₹946 from April...",
  "supporting_data": [
    { "label": "Top merchant", "value": "Swiggy", "trend": null },
    { "label": "MoM change", "value": "+8.2%", "trend": "up" }
  ],
  "confidence": 0.91
}
```

---

## Interfaces

### InsightGenerator Protocol

```swift
/// Primary protocol for generating financial insights.
public protocol InsightGenerator: Sendable {
    /// Generate a single insight for the given type and period.
    func generate(
        type: InsightType,
        period: DateInterval,
        context: InsightContext
    ) async throws -> InsightResult

    /// Generate all requested insight types in a single batched LLM call.
    func generateBatch(
        types: [InsightType],
        period: DateInterval
    ) async throws -> [InsightResult]
}
```

### InsightDataAggregator Protocol

```swift
public protocol InsightDataAggregator: Sendable {
    func buildContext(for period: DateInterval) async throws -> InsightContext
}
```

### InsightRepository Protocol

```swift
public protocol InsightRepository: Sendable {
    func save(_ insight: InsightResult) async throws
    func fetch(type: InsightType, period: DateInterval) async throws -> InsightResult?
    func fetchAll(period: DateInterval) async throws -> [InsightResult]
    func invalidate(period: DateInterval) async throws
}
```

### PromptBuilder Protocol

```swift
public protocol PromptBuilder: Sendable {
    func buildSystemPrompt() -> String
    func buildInsightPrompt(type: InsightType, context: InsightContext) -> String
    func buildBatchPrompt(types: [InsightType], context: InsightContext) -> String
}
```

### LLMProvider Protocol (shared with 021)

```swift
public protocol LLMProvider: Sendable {
    func generate(prompt: String, maxTokens: Int) async throws -> String
    func generateStream(
        prompt: String,
        maxTokens: Int
    ) -> AsyncThrowingStream<String, Error>
}
```

---

## Implementation Plan

### Step 1 — InsightDataAggregator (Week 1)

- Implement `GRDBInsightDataAggregator` using `TransactionRepository`
- Aggregate transactions by category, merchant, time bucket
- Compute MoM deltas against prior period
- Identify recurring commitments from `RecurringTransactionRepository`
- Identify unusual transactions (3-sigma or 3x 90-day average)
- Unit test: fixed transaction fixture → deterministic `InsightContext` JSON

### Step 2 — PromptBuilder (Week 1)

- Implement `FinancialAdvisorPromptBuilder`
- System prompt: persona as "concise Indian personal finance advisor, respond in JSON only"
- Per-type instruction templates that constrain output shape
- Batch prompt: JSON schema injected into prompt for structured output
- Unit test: context fixture → prompt string matches snapshot

### Step 3 — InsightParser (Week 2)

- `JSONDecoder`-based parser for LLM output
- Repair strategy for common LLM JSON defects (trailing commas, markdown fences)
- Confidence normalization: clamp to [0.0, 1.0], default 0.5 if missing
- Unit test: 20 representative LLM outputs including malformed edge cases

### Step 4 — LLMInsightGenerator (Week 2)

- Implement `InsightGenerator` protocol
- Single-type path: build prompt → call `LLMProvider.generate` → parse
- Batch path: build batch prompt → single `LLMProvider.generate` call → parse array
- Retry: one retry on JSON parse failure with simplified prompt
- Integrate `InsightRepository` cache: return cached result if age < TTL

### Step 5 — Migration from SpendingInsightEngine (Week 3)

- `SpendingInsightEngine` produces rule-based `SpendingInsight` values
- Bridge: `LegacyInsightAdapter` wraps `SpendingInsightEngine` → `InsightResult`
- Feature flag: `InsightGeneratorFactory.make()` returns LLM or legacy based on flag
- Keep `SpendingInsightEngine` as fallback for no-LLM environments

### Step 6 — ViewModel Integration (Week 3)

- `InsightsViewModel` owns `InsightGenerator` via DI
- Exposes `@Published var insights: [InsightResult]`
- Triggers `generateBatch` on first load and after import
- Shows stale cached insights during regeneration

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| LLM produces invalid JSON | High | Medium | Repair parser + one retry with stripped prompt |
| Hallucinated figures in body text | Medium | High | Body text is display-only; `supportingData` values come from aggregator, not LLM |
| Latency exceeds 10s for batch | Medium | Medium | Cache; batch only on background thread; show partial results as they parse |
| SpendingInsightEngine produces better output for simple cases | Low | Low | Keep as fallback behind flag |
| Model not loaded at insight generation time | Low | High | `ModelManager.ensureLoaded()` called before generation; degrade to legacy |

---

## Benchmarks

| Metric | Target | Measurement Method |
|---|---|---|
| Single insight latency | < 3s (Mac), < 8s (iPhone) | `ContinuousClock` around `generate()` call |
| Batch (7 types) latency | < 12s (Mac), < 30s (iPhone) | `ContinuousClock` around `generateBatch()` |
| Cache hit rate (same period) | > 95% | Insight store query count vs generate call count |
| JSON parse success rate | > 98% | `InsightParser` error counter |
| Confidence > 0.7 rate | > 80% | Distribution of `InsightResult.confidence` across test set |

---

## Testing Strategy

### Unit Tests

- `InsightDataAggregatorTests`: fixture transactions → deterministic `InsightContext`
- `PromptBuilderTests`: context → prompt string snapshot tests (20 scenarios)
- `InsightParserTests`: 20 LLM output strings including edge cases → correct `InsightResult`
- `LLMInsightGeneratorTests`: mock `LLMProvider` → verify retry logic, cache behaviour

### Integration Tests

- Full pipeline with a real model (Qwen3 4B) against 10 curated transaction fixtures
- Assert: headline is non-empty, `supportingData` values match aggregated ground truth
- Assert: batch call produces exactly the requested `InsightType` set

### Golden Tests

- Store 5 reference `InsightContext` JSON files and their expected `InsightResult` JSON
- Regenerate on model version bump; diff against reference; require human approval if body text changes materially

### Regression Tests

- `SpendingInsightEngine` output vs `LLMInsightGenerator` output on same fixture
- LLM results must not be factually contradicted by rule-based results
