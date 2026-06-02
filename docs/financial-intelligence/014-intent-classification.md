---
doc: 014-intent-classification
version: 0.1.0
status: Draft
date: 2026-06-02
---

# Intent Classification — Model 3

## Purpose

Define the complete design for the Intent Classification model. Intent is distinct from category: where category describes *what was purchased*, intent describes *why the money moved*. A credit card payment (`category: creditCardPayment`) and a loan EMI (`category: loanPayment`) are both debit transfers but have different intents (`payDebt` vs. `payEMI`). Intent powers behavioral intelligence: recurring commitment detection, financial health scoring, and the agent's understanding of spending patterns.

---

## Intent vs. Category

| Narration | Category | Intent |
|---|---|---|
| `SALARY CREDIT` | salary | receiveSalary |
| `LIC PREMIUM` | insurance | payInsurance |
| `HDFC CC PAYMENT` | creditCardPayment | payDebt |
| `ZERODHA SIP` | investments | investSIP |
| `RENT PAYMENT` | rent | payRent |
| `ZOMATO FOOD` | dining | food |
| `AMAZON REFUND` | refund | receiveRefund |
| `ATM CASH` | other | withdrawCash |
| `NETFLIX` | subscription | paySubscription |
| `UPI-SEND TO FRIEND` | peerTransfer | sendMoney |

Intent provides a behavioral dimension that category does not capture. Category is noun-like ("what"); intent is verb-like ("why").

---

## Intent Taxonomy (25 classes)

```swift
public enum TransactionIntent: String, Codable, CaseIterable {
    // Income intents
    case receiveSalary
    case receiveBonus
    case receiveFreelance
    case receiveRental
    case receiveDividend
    case receiveRefund
    case receiveCashback

    // Obligation intents
    case payRent
    case payInsurance
    case payEMI             // loan/EMI repayment
    case payDebt            // credit card bill
    case paySubscription    // recurring subscription
    case payUtility         // electricity, water, internet
    case payTax             // income tax, GST

    // Spending intents
    case buyGroceries
    case buyFood            // dining + delivery
    case buyFuel
    case buyTravel
    case shopping           // general purchase
    case payHealthcare
    case payEducation

    // Transfer intents
    case sendMoney          // peer transfer (outbound)
    case receiveMoney       // peer transfer (inbound)
    case investSIP          // mutual fund SIP
    case withdrawCash       // ATM

    case unknown
}
```

---

## Model Architecture

Intent classification benefits from category as a prior feature. Two architectures considered:

### Option A: Joint Category+Intent Model

Single model outputs (category, intent) simultaneously. More efficient but requires joint label dataset.

### Option B: Intent-Conditioned on Category

Intent model receives category prediction as an input feature. Requires Model 2 output upstream. This is the pipeline order already established.

**Decision: Option B (conditioned on category). Training dataset labels both; category is fed as a feature token. If Category confidence < 0.60, omit category feature to avoid error propagation.**

### Input

```
feature_string = "{narration} [CAT:{category}] [DIR:{direction}] [CH:{channel}] [MERCH:{merchant}]"
```

Examples:
```
"SALARY CREDIT NEFT [CAT:salary] [DIR:credit] [CH:neft] [MERCH:Acme Corp]"
"SWIGGY FOOD ORDER [CAT:dining] [DIR:debit] [CH:upi] [MERCH:Swiggy]"
"HDFC CC PAYMENT [CAT:creditCardPayment] [DIR:debit] [CH:neft] [MERCH:HDFC Bank]"
```

---

## Training Data Requirements

### Dataset Structure (`intent_training.csv`)

```csv
narration,merchant,category,direction,amount,payment_channel,intent,confidence
SALARY CREDIT HDFC,Acme Corp,salary,credit,85000,neft,receiveSalary,high
ZERODHA SIP NACH,Zerodha,investments,debit,5000,nach,investSIP,high
LIC PREMIUM NACH,LIC,insurance,debit,2500,nach,payInsurance,high
HDFC CC PAYMENT,HDFC Bank,creditCardPayment,debit,12000,neft,payDebt,high
SWIGGY FOOD ORDER,Swiggy,dining,debit,450,upi,buyFood,high
ZEPTO MARKETPLACE,Zepto,groceries,debit,849,upi,buyGroceries,high
UPI-FRIEND NAME,Unknown,peerTransfer,debit,2000,upi,sendMoney,high
AMAZON REFUND,Amazon,refund,credit,1299,neft,receiveRefund,high
ATM CASH WITHDRAWAL,ATM,other,debit,5000,cash,withdrawCash,high
```

### Size Targets

| Requirement | Target |
|---|---|
| Total training examples | 150,000+ |
| Minimum per intent class | 300 |
| Critical class minimum | 1,000 (receiveSalary, payDebt, payInsurance) |
| Test set size | 7,500 (stratified) |

### Critical Classes

These intents have outsized impact on financial insights if misclassified:

| Intent | Failure Impact | Minimum Recall |
|---|---|---|
| `receiveSalary` | Cash flow analysis wrong | 0.98 |
| `payDebt` | Debt tracking wrong | 0.95 |
| `payInsurance` | Protection coverage wrong | 0.93 |
| `investSIP` | Investment tracking wrong | 0.95 |
| `payRent` | Housing expense wrong | 0.95 |

---

## Intent Derivation from Category

For weak labeling of unlabeled data (auto-label by rule for training bootstrapping):

```python
CATEGORY_TO_INTENT_DEFAULTS = {
    "salary":             "receiveSalary",
    "dividend":           "receiveDividend",
    "refund":             "receiveRefund",
    "cashback":           "receiveCashback",
    "freelance":          "receiveFreelance",
    "rental":             "receiveRental",
    "rent":               "payRent",
    "insurance":          "payInsurance",
    "loanPayment":        "payEMI",
    "creditCardPayment":  "payDebt",
    "subscription":       "paySubscription",
    "investments":        "investSIP",
    "food":               "buyFood",
    "dining":             "buyFood",
    "groceries":          "buyGroceries",
    "fuel":               "buyFuel",
    "travel":             "buyTravel",
    "peerTransfer":       "sendMoney",
}
```

**Important:** Auto-labeled examples are used only for pre-training. Human-labeled examples must dominate the final training set for critical classes.

---

## Intent-Specific Disambiguation

### sendMoney vs. receiveMoney

Same narration format; differ by `direction`:
- `direction == debit` → `sendMoney`
- `direction == credit` → `receiveMoney`

This should not require ML — encode as a structural rule applied post-intent prediction.

### investSIP vs. selfTransfer

Both are debit transfers. Disambiguation by merchant:
- Zerodha, Groww, Upstox, Kuvera, INDmoney, Paytm Money → `investSIP`
- Own account patterns → `selfTransfer`

Model 1 merchant output is critical input for this disambiguation.

### payDebt vs. payEMI

Both reduce financial obligations. Disambiguation:
- "CC PAYMENT", "CREDIT CARD BILL" → `payDebt`
- "EMI", "LOAN", "MORTGAGE" → `payEMI`

---

## Swift Implementation

```swift
// IntentDetection/CoreMLIntentClassifier.swift

public final class CoreMLIntentClassifier: IntentClassifier {
    private let model: NLModel
    private let featureExtractor: IntentFeatureExtractor
    private let categoryIntentMap: [TransactionCategory: TransactionIntent]

    public init(registry: any ModelRegistry) throws {
        let mlModel = try registry.loadCoreML(.intent)
        self.model = try NLModel(mlModel: mlModel)
        self.featureExtractor = IntentFeatureExtractor()
        self.categoryIntentMap = Self.buildFallbackMap()
    }

    public func classify(_ input: IntentInput) async -> IntentPrediction {
        let features = featureExtractor.extract(input)
        let hypotheses = model.predictedLabelHypotheses(for: features, maximumCount: 3)

        guard let (topLabel, topConfidence) = hypotheses.max(by: { $0.value < $1.value }),
              let intent = TransactionIntent(rawValue: topLabel) else {
            // Structural fallback: derive from direction + category
            let fallback = structuralFallback(input)
            return IntentPrediction(intent: fallback, confidence: 0.30, source: .fallback)
        }

        // Direction-based override for sendMoney/receiveMoney
        let finalIntent = applyDirectionOverride(intent, direction: input.direction)

        return IntentPrediction(intent: finalIntent, confidence: Float(topConfidence), source: .model)
    }

    private func applyDirectionOverride(_ intent: TransactionIntent,
                                        direction: TransactionDirection) -> TransactionIntent {
        switch (intent, direction) {
        case (.sendMoney, .credit), (.receiveMoney, .debit):
            return direction == .credit ? .receiveMoney : .sendMoney
        default:
            return intent
        }
    }
}
```

---

## Performance Targets

| Metric | Target |
|---|---|
| Macro F1 | ≥ 0.95 |
| Weighted F1 | ≥ 0.96 |
| receiveSalary recall | ≥ 0.98 |
| payDebt recall | ≥ 0.95 |
| investSIP recall | ≥ 0.95 |
| P95 inference latency | < 15 ms |
| Model size | < 20 MB |

---

## Integration with Pipeline

Intent prediction feeds:
1. `RecurringDetector` (Stage 7) — `payRent`, `payInsurance`, `investSIP`, `paySubscription` signal recurring intents
2. `InsightGenerator` (Model 11) — intent distribution is primary input for cashflow narrative
3. `FinanceAgent` — agent uses intent to answer "how much did I spend on obligations this month?"
4. `SpendingInsightEngine` — intent-based spend bucketing (obligations vs. discretionary vs. investments)

---

## Risks

| Risk | Mitigation |
|---|---|
| Category error propagates to intent | Set confidence threshold: only use category feature if confidence ≥ 0.60 |
| Intent taxonomy too granular (25 classes, sparse data) | Merge rare classes; keep taxonomy flexible (add new intents without retraining if bucketed) |
| sendMoney/receiveMoney confusion | Apply direction structural override post-inference |
| Model conflates investSIP with selfTransfer | Require merchant embedding from Model 1 as feature; investment platforms explicitly labeled |
