---
doc: 015-recurring-detection
version: 0.1.0
status: Draft
date: 2026-06-02
---

# Recurring Detection — Model 4

## Purpose

Define the complete design for the Recurring Detection model. Recurring detection identifies transactions that form a temporal pattern — the same (or similar) amount paid to the same merchant at regular intervals. This powers: subscription tracking, rent reminders, bill calendar, cash flow forecasting, and anomaly detection (detecting when a recurring payment is missed or changed).

---

## Problem Statement

The current `RecurringDetector` uses hardcoded cadence windows (`[7, 14, 30, 90]` days) and a fixed amount tolerance (±5%). Failure modes:

1. **Monthly bills with variable dates**: Electricity bill arrives between day 3–8 each month → falls outside 30-day window
2. **Variable-amount recurring**: Insurance premium with annual hike; utility bills that vary ±15%
3. **Irregular-but-recurring**: Quarterly broker charges, annual Amazon Prime, semi-annual domain renewal
4. **New merchant with 1 occurrence**: Cannot classify as recurring — need at least 2 data points
5. **Cadence drift**: Netflix raises price; detector thinks it's a new transaction

---

## Architecture

```
[Input: Transaction Sequence]
  (merchant, amount, date, direction) × N transactions
          │
          ▼
[Feature Engineering]
  Per-sequence features (see below)
          │
          ▼
[CoreML Tabular Regressor]
  Input: Float[16] feature vector
  Output: (is_recurring: Bool, cadence: RecurringCadence, confidence: Float)
          │
          ▼
[Post-Processing]
  • Next expected date estimation
  • Amount range prediction (±σ)
  • Subscription detector handoff (Model 5)
```

---

## Feature Engineering

The model operates on **merchant transaction sequences** — all past transactions for the same merchant, sorted by date.

```python
def extract_recurring_features(sequence: list[Transaction]) -> dict:
    """
    Extracts 16 features from a merchant transaction sequence.
    Minimum sequence length: 2. For sequences of length 1, return is_recurring=False.
    """
    if len(sequence) < 2:
        return {"is_recurring": False}
    
    amounts = [t.amount for t in sequence]
    dates = sorted([t.date for t in sequence])
    intervals = [(dates[i+1] - dates[i]).days for i in range(len(dates)-1)]
    
    return {
        # Amount features
        "amount_mean": statistics.mean(amounts),
        "amount_std": statistics.stdev(amounts) if len(amounts) > 1 else 0,
        "amount_cv": (statistics.stdev(amounts) / statistics.mean(amounts)
                      if len(amounts) > 1 and statistics.mean(amounts) > 0 else 0),
        "amount_max_delta_pct": (max(amounts) - min(amounts)) / statistics.mean(amounts),
        
        # Interval features
        "interval_mean": statistics.mean(intervals),
        "interval_std": statistics.stdev(intervals) if len(intervals) > 1 else 0,
        "interval_cv": (statistics.stdev(intervals) / statistics.mean(intervals)
                        if len(intervals) > 1 and statistics.mean(intervals) > 0 else 0),
        "interval_min": min(intervals),
        "interval_max": max(intervals),
        
        # Cadence alignment features
        "aligns_7d": cadence_alignment_score(intervals, 7),
        "aligns_14d": cadence_alignment_score(intervals, 14),
        "aligns_30d": cadence_alignment_score(intervals, 30),
        "aligns_90d": cadence_alignment_score(intervals, 90),
        "aligns_365d": cadence_alignment_score(intervals, 365),
        
        # Sequence features
        "sequence_length": len(sequence),
        "day_of_month_std": statistics.stdev([d.day for d in dates]) if len(dates) > 1 else 0,
    }


def cadence_alignment_score(intervals: list[int], target: int) -> float:
    """
    Returns 0.0–1.0 indicating how well intervals align to target cadence.
    Uses circular distance modulo target.
    """
    if not intervals:
        return 0.0
    distances = [min(abs(i - target), target - abs(i - target) % target)
                 for i in intervals]
    return 1.0 - (statistics.mean(distances) / (target / 2))
```

---

## Cadence Classification

Post-regression, a separate classifier maps predicted cadence float to enum:

| `interval_mean` range | `RecurringCadence` |
|---|---|
| 5–9 days | `.weekly` |
| 12–16 days | `.biweekly` |
| 27–33 days | `.monthly` |
| 58–92 days | `.quarterly` |
| 170–195 days | `.biannual` |
| 350–380 days | `.annual` |
| All other | `.irregular` |

Irregular-but-recurring: `is_recurring = true` but `cadence = .irregular`. These are valid recurring transactions that don't fit standard cadences.

---

## Training Data Requirements

### Positive Examples (Recurring)

```csv
# recurring_training.csv
merchant,amount,dates,is_recurring,cadence,label_source
Netflix,649,2026-01-05|2026-02-05|2026-03-05|2026-04-05,true,monthly,human
Zerodha SIP,5000,2026-01-01|2026-02-01|2026-03-01,true,monthly,human
BESCOM,1200|1350|1180,2026-01-10|2026-02-09|2026-03-11,true,monthly,human
LIC,12000,2026-01-15|2026-04-15|2026-07-15|2026-10-15,true,quarterly,human
Amazon Prime,1499,2025-06-01|2026-06-01,true,annual,human
```

### Negative Examples (Non-Recurring)

Mix of:
- One-time transactions (single occurrence per merchant)
- Sporadic patterns (same merchant, irregular amounts, irregular dates)
- Coincidental repeats (two similar payments, different intent)

### Size Targets

| Requirement | Target |
|---|---|
| Positive recurring sequences | 10,000+ |
| Negative non-recurring sequences | 10,000+ |
| Cadence balance (monthly should not dominate) | Cap monthly at 40% of positives |
| Irregular recurring examples | ≥ 1,000 |
| Edge cases (1–2 occurrence sequences) | ≥ 2,000 |

---

## Next Expected Date Estimation

After classification, estimate when the next payment is due:

```swift
func estimateNextDate(sequence: [Date], cadence: RecurringCadence) -> Date? {
    guard let lastDate = sequence.max() else { return nil }
    
    switch cadence {
    case .weekly:    return Calendar.current.date(byAdding: .day, value: 7, to: lastDate)
    case .biweekly:  return Calendar.current.date(byAdding: .day, value: 14, to: lastDate)
    case .monthly:   return Calendar.current.date(byAdding: .month, value: 1, to: lastDate)
    case .quarterly: return Calendar.current.date(byAdding: .month, value: 3, to: lastDate)
    case .biannual:  return Calendar.current.date(byAdding: .month, value: 6, to: lastDate)
    case .annual:    return Calendar.current.date(byAdding: .year, value: 1, to: lastDate)
    case .irregular, .daily: return nil
    }
}
```

For monthly cadence: also record `day_of_month_mean` to predict expected day (e.g., "usually arrives on the 5th").

---

## Integration with Subscription Detector (Model 5)

Recurring transactions are passed to Model 5 for subscription classification:

```
RecurringPrediction(isRecurring: true, cadence: .monthly)
         +
MerchantPrediction(canonicalName: "Netflix")
         ↓
SubscriptionDetector.detect(→ isSubscription: true, serviceName: "Netflix")
```

---

## Swift Implementation

```swift
// RecurringDetection/CoreMLRecurringDetector.swift

public final class CoreMLRecurringDetector: RecurringDetector {
    private let model: MLModel
    private let featureExtractor: RecurringFeatureExtractor
    private let sequenceFetcher: RecurringSequenceFetcher

    public func detect(_ transaction: StructuredTransaction) async -> RecurringPrediction {
        // Fetch last 12 months of same-merchant transactions
        let sequence = await sequenceFetcher.fetch(merchant: transaction.merchantName,
                                                   lookbackDays: 365)
        
        guard sequence.count >= 2 else {
            return RecurringPrediction(isRecurring: false, cadence: nil,
                                      confidence: 0.90, nextExpectedDate: nil,
                                      expectedAmountRange: nil)
        }
        
        let features = featureExtractor.extract(sequence + [transaction])
        let input = RecurringDetectorInput(features: features)
        let output = try? model.prediction(from: input)
        
        guard let isRecurring = output?.isRecurring, isRecurring else {
            return RecurringPrediction(isRecurring: false, cadence: nil,
                                      confidence: output?.notRecurringConfidence ?? 0.70,
                                      nextExpectedDate: nil, expectedAmountRange: nil)
        }
        
        let cadence = RecurringCadence(intervalMean: features.intervalMean)
        let nextDate = estimateNextDate(sequence: sequence.map { $0.date }, cadence: cadence)
        let amountRange = estimateAmountRange(amounts: sequence.map { $0.amount })
        
        return RecurringPrediction(isRecurring: true, cadence: cadence,
                                  confidence: output?.recurringConfidence ?? 0.80,
                                  nextExpectedDate: nextDate,
                                  expectedAmountRange: amountRange)
    }
}
```

---

## Performance Targets

| Metric | Target |
|---|---|
| Binary Precision (recurring) | ≥ 0.90 |
| Binary Recall (recurring) | ≥ 0.88 |
| Monthly cadence F1 | ≥ 0.90 |
| Irregular cadence detection recall | ≥ 0.70 |
| Next-date accuracy (within ±3 days) | ≥ 0.80 for monthly |
| P95 latency (including DB fetch) | < 30 ms |

---

## Risks

| Risk | Mitigation |
|---|---|
| Insufficient transaction history for new users | Model trained to output `is_recurring: false` with high confidence when `sequence_length < 2` |
| Merchant name variations break sequence grouping | Use Model 1 canonical merchant name as grouping key, not raw narration |
| Monthly bills with date drift (±5 days) | `aligns_30d` feature tolerates drift via circular distance; not hard window |
| NACH/auto-debit always recurring regardless of merchant | Payment channel is NOT sufficient — same NACH merchant must appear multiple times |
