---
doc: 013-category-classification
version: 0.1.0
status: Draft
date: 2026-06-02
---

# Category Classification — Model 2

## Purpose

Define the complete design for the Category Classification model: the two-level taxonomy, model architecture, feature engineering, training data strategy, evaluation approach, subcategory support, and integration with the inference pipeline.

---

## Current State

`CoreMLCategorizer` is deployed and running in production with a single-level taxonomy. Known issues:
- No subcategory support
- No version-pinned artifact
- Confidence threshold (`0.65`) undocumented
- No evaluation harness; actual F1 unknown
- `RuleBasedCategorizer` still running as fallback (keyword matching)

This document defines the target state.

---

## Two-Level Taxonomy

### Level 1: Category (28 classes)

| Category | Examples |
|---|---|
| `food` | General food spending |
| `groceries` | Supermarket, grocery stores |
| `dining` | Restaurants, cafes, food delivery |
| `travel` | Flights, hotels, trains, buses |
| `fuel` | Petrol, diesel, EV charging |
| `shopping` | E-commerce, retail |
| `entertainment` | Movies, events, gaming |
| `utilities` | Electricity, water, internet, mobile |
| `healthcare` | Pharmacy, hospitals, diagnostics |
| `education` | Schools, courses, books |
| `personalCare` | Salon, spa, cosmetics |
| `rent` | Rent payments |
| `insurance` | Life, health, vehicle, property |
| `loanPayment` | EMI, loan repayment |
| `creditCardPayment` | Credit card bill payments |
| `subscription` | OTT, software, news subscriptions |
| `peerTransfer` | Sending money to individuals |
| `selfTransfer` | Own account transfers |
| `investments` | Stocks, mutual funds, NPS, FD |
| `savingsDeposit` | RD, savings account top-ups |
| `salary` | Salary credits |
| `freelance` | Freelance/consulting income |
| `rental` | Rental income |
| `dividend` | Dividend, interest credits |
| `refund` | Refunds, reversals |
| `cashback` | Cashback, rewards |
| `fees` | Bank fees, service charges |
| `other` | Catch-all |

### Level 2: Subcategory (selected categories)

| Category | Subcategories |
|---|---|
| `travel` | flight, hotel, train, bus, cab, metro, toll, parking |
| `shopping` | electronics, clothing, furniture, books, sports, beauty |
| `utilities` | electricity, water, internet, mobile, gas |
| `healthcare` | pharmacy, hospital, diagnostics, dental, optical |
| `investments` | mutualFund, stocks, nps, ppf, gold, crypto, fd |
| `subscription` | streaming, software, news, gaming, fitness |

---

## Model Architecture

### Option A: NLModel (fastText-style)

- Faster inference (< 10 ms)
- Smaller model size (< 5 MB)
- Lower accuracy ceiling (~88% macro F1)
- Direct CoreML export

### Option B: DistilBERT fine-tuned → CoreML

- Higher accuracy ceiling (~93-95% macro F1)
- Larger model (50-80 MB)
- Slower inference (~30-50 ms)
- Requires `coremltools` export + quantization

**Decision: Train Option B (DistilBERT) for quality; quantize to 8-bit for size/latency. Evaluate latency post-quantization; fall back to Option A if P95 > 30 ms.**

### Model Input

```
feature_string = "{narration} [SEP] {merchant_name} [SEP] {payment_channel}"
```

Max token length: 128. Truncate from right.

---

## Training Data Requirements

### Dataset Structure (`category_training.csv`)

```csv
narration,merchant,payment_channel,direction,amount,category,subcategory,confidence
UPI-ZEPTO MARKETPLACE PR,Zepto,upi,debit,349.0,groceries,,high
SWIGGY FOOD ORDER,Swiggy,upi,debit,450.0,dining,,high
SALARY CREDIT NEFT,Acme Corp,neft,credit,85000.0,salary,,high
NETFLIX.COM,Netflix,card,debit,649.0,subscription,streaming,high
HDFC CC PAYMENT,HDFC Bank,neft,debit,12500.0,creditCardPayment,,high
LIC PREMIUM,LIC,nach,debit,5000.0,insurance,,high
ZERODHA HOLDINGS,Zerodha,upi,debit,25000.0,investments,mutualFund,high
```

### Size Targets

| Requirement | Target |
|---|---|
| Total training examples | 200,000+ |
| Minimum per category class | 500 |
| Minimum per subcategory class | 100 |
| Test set size | 10,000 (stratified) |
| Unknown/edge cases | 5,000 |

### Class Imbalance Strategy

Real transaction distributions are highly imbalanced (groceries >> taxes). Mitigation:

1. Oversample minority classes in training batch
2. Use class-weighted loss function
3. Report Macro F1 (not accuracy) as primary metric
4. Set minimum per-class recall floor of 0.70

---

## Feature Engineering

### Text Preprocessing

```python
def preprocess_for_category(narration: str, merchant: str, channel: str) -> str:
    """Build feature string for category classifier."""
    # Normalize case
    narration = narration.upper()
    # Remove reference IDs
    narration = re.sub(r'\b\d{6,}\b', '', narration)
    # Remove UPI gateway suffixes
    narration = re.sub(r'@\w+', '', narration)
    # Clean whitespace
    narration = ' '.join(narration.split())
    
    return f"{narration} {merchant or ''} {channel}"
```

### Amount Binning (Supplementary Feature for Subcategory)

Amount range provides signal for subcategory disambiguation:
- Salary: typically > ₹10,000 credit
- Dining: typically ₹100–₹1,500
- Flight: typically ₹2,000–₹30,000

Amount bin (log-scale) added as a special token: `[AMT:HIGH]`, `[AMT:MED]`, `[AMT:LOW]`

---

## Hierarchical Classification Strategy

### Option 1: Flat Multi-Class

Train one model for all (category, subcategory) pairs as flat labels. Simpler but requires more data per leaf.

### Option 2: Two-Stage Hierarchy

Stage 1: Predict category (28 classes)
Stage 2: Predict subcategory conditioned on category (only for categories with subcategories)

**Decision: Start with flat multi-class. Switch to two-stage if subcategory accuracy is poor (< 0.80 F1) for any subcategory.**

---

## Swift Implementation

```swift
// Categorization/CoreMLCategoryClassifier.swift

public final class CoreMLCategoryClassifier: CategoryClassifier {
    private let model: NLModel
    private let featureExtractor: CategoryFeatureExtractor
    private let confidenceThreshold: Float

    public init(registry: any ModelRegistry, confidenceThreshold: Float = 0.65) throws {
        let mlModel = try registry.loadCoreML(.category)
        self.model = try NLModel(mlModel: mlModel)
        self.featureExtractor = CategoryFeatureExtractor()
        self.confidenceThreshold = confidenceThreshold
    }

    public func classify(_ input: CategoryInput) async -> CategoryPrediction {
        let features = featureExtractor.extract(input)
        let hypotheses = model.predictedLabelHypotheses(for: features, maximumCount: 5)

        let sorted = hypotheses.sorted { $0.value > $1.value }
        guard let top = sorted.first else {
            return CategoryPrediction(category: .other, subcategory: nil,
                                     confidence: 0, source: .fallback, topAlternatives: [])
        }

        let category = TransactionCategory(rawValue: top.key) ?? .other
        let confidence = Float(top.value)
        let source: PredictionSource = confidence >= confidenceThreshold ? .model : .fallback

        let alternatives = sorted.dropFirst().prefix(3).compactMap { entry -> CategoryPrediction.CategoryCandidate? in
            guard let cat = TransactionCategory(rawValue: entry.key) else { return nil }
            return CategoryPrediction.CategoryCandidate(category: cat, confidence: Float(entry.value))
        }

        return CategoryPrediction(category: category, subcategory: nil,
                                 confidence: confidence, source: source,
                                 topAlternatives: alternatives)
    }
}
```

---

## A/B Testing Plan

Before retiring `RuleBasedCategorizer` as fallback:

1. Log both predictions (CoreML + Rule) for 2 weeks on real transactions
2. Use user corrections as ground truth proxy
3. Compute correction rate for each model
4. If CoreML correction rate ≤ Rule correction rate: promote CoreML as sole classifier
5. Retire `RuleBasedCategorizer` from hot path

---

## Performance Targets

| Metric | Target |
|---|---|
| Macro F1 | ≥ 0.92 |
| Weighted F1 | ≥ 0.94 |
| Min per-class recall | ≥ 0.70 |
| salary precision | ≥ 0.99 |
| creditCardPayment recall | ≥ 0.95 |
| Model size | < 80 MB (quantized) |
| P95 inference latency | < 20 ms |
| ECE | < 0.05 |

---

## Confusion Matrix Failure Modes to Monitor

| Frequently Confused Pair | Disambiguation Signal |
|---|---|
| groceries ↔ dining | Merchant name (Zepto/Blinkit → groceries; Swiggy/Zomato → dining) |
| salary ↔ peerTransfer | Amount (large round credit + NEFT = salary) |
| creditCardPayment ↔ loanPayment | Narration: "CC PAYMENT" vs. "EMI" |
| shopping ↔ groceries | Merchant category (Amazon → shopping; BigBasket → groceries) |
| investments ↔ selfTransfer | VPA domain (zerodha, groww, navi = investments) |

---

## Risks

| Risk | Mitigation |
|---|---|
| DistilBERT too large after quantization | Evaluate NLModel Option A as fallback; quantize to 4-bit if needed |
| Salary vs. transfer confusion causes financial reporting errors | Add salary as critical class; set explicit recall floor; alert on category switches |
| Subcategory training data sparse | Phase subcategory support — ship category first, add subcategory in v2 |
| Indian-specific merchants OOV for pre-trained DistilBERT | Fine-tune on Indian financial narrations corpus; vocabulary expansion if needed |
