---
doc: 017-anomaly-detection
version: 0.1.0
status: Draft
date: 2026-06-02
---

# Anomaly Detection — Model 9

## Purpose

Define the complete design for the Anomaly Detection model. Anomaly detection identifies transactions that are unusual relative to a user's historical behavior — unexpectedly large amounts, new merchants in a known category, spending category spikes, missed recurring payments, and potential duplicate transactions. This powers: fraud-like behavior alerts, budget overage notifications, and the agent's ability to proactively surface unusual financial activity.

---

## Anomaly Taxonomy

| Anomaly Type | Description | Example |
|---|---|---|
| `unusuallyLargeAmount` | Amount significantly exceeds user's historical distribution for merchant/category | Swiggy order ₹4,500 when typical is ₹350–₹600 |
| `unusuallySmallAmount` | Amount significantly below distribution | Rent ₹5,000 when usual is ₹25,000 (partial payment?) |
| `newMerchantInCategory` | First transaction with a merchant in a known category | First time buying from a new pharmacy |
| `categorySpike` | Spend in a category significantly exceeds monthly baseline | Entertainment ₹8,000 vs usual ₹500/month |
| `merchantSpike` | Spend at a specific merchant exceeds merchant baseline | Amazon ₹45,000 vs usual ₹3,000/month |
| `duplicateSuspected` | Two near-identical transactions within a short window | Same amount, same merchant, 2 minutes apart |
| `recurringAmountChanged` | A recurring payment amount has significantly changed | Netflix ₹649 → ₹799 (price hike) |
| `unexpectedFee` | Bank fee or charge with no recent preceding activity | ₹590 debit with narration "ANNUAL FEE" |
| `missedRecurring` | Expected recurring payment has not appeared | Rent not seen on 5th; today is 10th |

---

## Architecture: Two-Stage Detection

```
Stage 1: Statistical Baseline (fast, always runs)
  • z-score on amount vs. per-merchant/category distribution
  • Duplicate detection (exact match within 5-minute window)
  • Categorical spike detection (monthly roll-up vs. baseline)
  • Always available, no model required

Stage 2: ML Refinement (CoreML tabular, filters false positives)
  • Reduces false positive rate from ~15% (statistical) to <5% (ML)
  • Input: statistical anomaly score + transaction features
  • Output: calibrated anomaly confidence
```

Stage 1 is always active. Stage 2 refines Stage 1 outputs only (not a standalone detector).

---

## Statistical Baseline

### Amount Distribution Model

```python
# Per user, per merchant: model amount distribution
# Fitted from last 12 months of history
# Updated incrementally after each import

class AmountDistributionModel:
    def __init__(self):
        self.stats: dict[str, AmountStats] = {}  # merchant → stats
    
    def fit(self, transactions: list[Transaction]):
        by_merchant = group_by_merchant(transactions)
        for merchant, txns in by_merchant.items():
            amounts = [t.amount for t in txns if t.direction == "debit"]
            if len(amounts) < 3:
                continue  # insufficient history
            self.stats[merchant] = AmountStats(
                mean=statistics.mean(amounts),
                std=statistics.stdev(amounts),
                p25=percentile(amounts, 25),
                p75=percentile(amounts, 75),
                max=max(amounts),
                n=len(amounts)
            )
    
    def zscore(self, merchant: str, amount: float) -> float | None:
        if merchant not in self.stats or self.stats[merchant].n < 3:
            return None
        stats = self.stats[merchant]
        if stats.std < 1.0:  # avoid division by near-zero
            return None
        return (amount - stats.mean) / stats.std
```

### Anomaly Threshold

```
|z-score| > 2.5 → flag as potential amount anomaly (high sensitivity)
|z-score| > 3.5 → flag as definite amount anomaly (high specificity)
```

---

## ML Refinement Model

The tabular model takes the statistical anomaly signal as input and learns which statistical anomalies are true anomalies vs. false positives.

### Features

```python
def extract_anomaly_features(
    transaction: Transaction,
    statistical_score: StatisticalAnomalyScore,
    user_history: UserHistory
) -> list[float]:
    return [
        # Amount features
        statistical_score.amount_zscore or 0.0,
        statistical_score.amount_pct_above_max,        # % above historical max
        statistical_score.amount_to_monthly_avg_ratio,
        
        # Transaction features
        transaction.amount,
        transaction.direction == "debit" ? 1.0 : 0.0,
        transaction.day_of_week / 7.0,
        transaction.hour_of_day / 24.0,
        
        # Merchant history features
        user_history.merchant_transaction_count(transaction.merchant),
        user_history.days_since_last_merchant_transaction(transaction.merchant),
        
        # Category features
        statistical_score.category_monthly_zscore or 0.0,
        user_history.category_transaction_count(transaction.category),
        
        # Duplicate features
        statistical_score.minutes_since_similar_transaction or 999.0,
        statistical_score.similar_amount_count_last_hour,
        
        # Recurring features
        statistical_score.expected_recurring_deviation_pct or 0.0,
        transaction.is_recurring ? 1.0 : 0.0,
        transaction.recurring_amount_change_pct or 0.0,
    ]
```

### Model Type

**Isolation Forest** trained on normal transactions (unsupervised). Labeled anomaly examples used for calibration and threshold tuning post-training.

Alternative: **One-Class SVM** (slightly better on structured features, slower).

Export: CoreML tabular model via `sklearn` → `coremltools`.

---

## Duplicate Detection

Special-case detection that runs before the ML stage:

```swift
func detectDuplicates(
    _ transaction: Transaction,
    recentTransactions: [Transaction]   // last 10 minutes from same account
) -> AnomalySignal? {
    let candidates = recentTransactions.filter { candidate in
        candidate.merchant == transaction.merchant &&
        abs(candidate.amount - transaction.amount) < 1.0 &&  // same amount within ₹1
        candidate.direction == transaction.direction
    }
    
    guard !candidates.isEmpty else { return nil }
    
    return AnomalySignal(
        type: .duplicateSuspected,
        severity: .high,
        confidence: 0.90,
        description: "Possible duplicate transaction to \(transaction.merchant) for ₹\(transaction.amount)",
        baselineValue: nil,
        observedValue: transaction.amount
    )
}
```

---

## UserHistory Materialization

`UserHistory` is a materialized in-memory snapshot, not computed per-transaction:

```swift
// AnomalyDetection/UserHistoryBuilder.swift

public final class UserHistoryBuilder {
    public func build(for accountID: AccountID, db: DatabaseQueue) async -> UserHistory {
        // Query: aggregate stats per merchant (last 365 days)
        // Query: monthly totals per category (last 12 months)
        // Query: recent transactions (last 10 minutes, for duplicate detection)
        // Cache result in memory for the import session lifetime
    }
}
```

Rebuilt at the start of each import session, not per-transaction. Ensures consistent baseline during batch processing.

---

## False Positive Management

False positives are the primary UX risk for anomaly detection. Strategy:

1. **Severity tiers:** Only `high` and `critical` anomalies surface to the user. `low` and `medium` are logged only.
2. **Minimum history requirement:** Do not flag amount anomalies for merchants with < 5 historical transactions.
3. **Merchant familiarity score:** Reduce anomaly confidence if user has transacted with merchant > 20 times.
4. **User feedback loop:** User can mark an anomaly as "expected" → suppressed for future similar transactions.

---

## Swift Implementation

```swift
// AnomalyDetection/CoreMLAnomalyDetector.swift

public final class CoreMLAnomalyDetector: AnomalyDetector {
    private let model: MLModel
    private let statisticalDetector: StatisticalAnomalyDetector
    private let featureExtractor: AnomalyFeatureExtractor

    public func detect(
        _ transaction: TransactionFeatures,
        history: UserHistory
    ) async -> AnomalySignal? {
        // Stage 1: statistical
        let statistical = statisticalDetector.detect(transaction, history: history)
        
        // Fast-path: duplicate detection always fires first
        if let duplicate = statistical.duplicateSignal {
            return duplicate
        }
        
        // If no statistical anomaly, skip ML (optimization)
        guard let stat = statistical.anomalyScore, stat > 1.5 else {
            return nil
        }
        
        // Stage 2: ML refinement
        let features = featureExtractor.extract(transaction, statistical: statistical, history: history)
        let input = AnomalyDetectorInput(features: features)
        guard let output = try? model.prediction(from: input),
              output.anomalyScore > 0.70 else {
            return nil  // ML overrides statistical false positive
        }
        
        return buildSignal(transaction: transaction, mlScore: output.anomalyScore, stat: stat)
    }
}
```

---

## Performance Targets

| Metric | Target |
|---|---|
| Precision at operating threshold | ≥ 0.80 |
| False Positive Rate | ≤ 0.05 |
| Recall on labeled anomalies | ≥ 0.75 |
| Duplicate detection precision | ≥ 0.95 |
| P95 latency | < 20 ms |
| UserHistory build time (1 year history) | < 500 ms (once per session) |

---

## Missed Recurring Detection

Model 9 is also responsible for detecting *absence* anomalies — expected recurring payments that haven't appeared:

```swift
// Runs as a scheduled daily job, not per-transaction
func detectMissedRecurring(
    expected: [RecurringItem],
    recentTransactions: [Transaction],
    today: Date
) -> [AnomalySignal] {
    expected.compactMap { item in
        guard let nextExpected = item.nextExpectedDate,
              nextExpected < today,
              Calendar.current.dateComponents([.day], from: nextExpected, to: today).day ?? 0 > 3
        else { return nil }
        
        let matched = recentTransactions.contains { txn in
            txn.merchant == item.merchant &&
            abs(txn.amount - item.expectedAmount) < item.expectedAmount * 0.10
        }
        
        guard !matched else { return nil }
        
        return AnomalySignal(type: .missedRecurring, severity: .medium, confidence: 0.85,
                             description: "\(item.merchant) payment overdue by \(days) days", ...)
    }
}
```

---

## Risks

| Risk | Mitigation |
|---|---|
| High false positive rate erodes user trust | Strict FPR ≤ 0.05 threshold; two-stage architecture; user feedback suppression |
| New user cold start (insufficient history) | Minimum history gate: 60 days + 30 transactions before anomaly detection activates |
| Price hike vs. anomaly (Netflix raises price) | `recurringAmountChanged` is advisory severity `.low`; user informed but not alarmed |
| Isolation Forest trains on contaminated data | Bootstrap with synthetic clean history; outlier fraction parameter set conservatively |
