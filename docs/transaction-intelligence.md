# Transaction Intelligence — Architecture & Developer Guide

## Overview

FinanceIntelligence is a local-first intelligence layer for FinanceOS. It performs:

1. **Merchant normalization** — converts noisy bank descriptions to canonical merchant names
2. **Category prediction** — assigns a versioned category + subcategory to each transaction
3. **Spending insights** — detects recurring charges, subscriptions, and spending spikes

All computation is on-device. No transaction data leaves the app.

---

## Architecture

```
Transaction (FinanceCore)
  ├─→ TransactionFeatureExtractor  →  TransactionFeatures
  ├─→ MerchantNormalizer           →  MerchantCandidate
  └─→ [CoreMLCategorizer ∨ RuleBasedCategorizer]  →  CategoryPrediction
         ↓
  AnalyzedTransaction
         ↓
  SpendingInsightEngine            →  [TransactionInsight]
```

`TransactionIntelligenceServiceImpl` orchestrates all steps as an actor.

---

## Data Flow

1. **Feature extraction**: Cleans description text, tokenizes, derives temporal features and boolean indicators (transfer, payroll, refund, recurring, online).
2. **Merchant normalization**:
   - Deterministic text cleaning (strip processor prefixes, transaction IDs, URLs, city/state noise)
   - Alias table lookup (`merchant_aliases.json` in bundle)
   - Fuzzy token matching for common merchants
   - Fallback: title-case cleaned description
3. **Category prediction**:
   - Check user corrections first (confidence = 1.0)
   - Use Core ML model if bundled and available
   - Fall back to alias-derived category if merchant matched
   - Fall back to `RuleBasedCategorizer` (keyword rules)
4. **Insight generation**: Pure statistical analysis over `[Transaction]` arrays — no ML required.

---

## Privacy Model

- All inference runs on-device.
- User corrections are stored in `~/Library/Application Support/FinanceIntelligence/corrections.json`.
- No data is transmitted externally.
- Training pipeline accepts **anonymized** CSV exports only.

---

## Category Taxonomy

Version: `1.0.0` — defined in `CategoryTaxonomy.swift` (`CategoryTaxonomy.v1`).

| ID | Display Name | Notable Subcategories |
|----|-------------|----------------------|
| income | Income | salary, dividend, refund |
| transfers | Transfers | internal, external |
| housing | Housing | rent, mortgage |
| utilities | Utilities | electricity, internet, phone |
| groceries | Groceries | |
| dining | Restaurants & Dining | restaurant, coffee, delivery |
| transportation | Transportation | rideshare, fuel, parking, transit |
| travel | Travel | flight, hotel, rental |
| healthcare | Healthcare | pharmacy, doctor, dental |
| insurance | Insurance | health, auto, life |
| subscriptions | Subscriptions | streaming, music, software |
| shopping | Shopping | online, clothing, electronics |
| entertainment | Entertainment | movies, games, sports |
| education | Education | tuition, books, courses |
| fees | Fees & Interest | bank, interest, late |
| taxes | Taxes | |
| business | Business | |
| atm | Cash & ATM | |
| uncategorized | Uncategorized | |

To add a new category: edit `CategoryTaxonomy.v1` and bump the version string.

---

## Merchant Normalization Strategy

### Stage 1: Deterministic preprocessing (`MerchantTextCleaner`)

Removes:
- Processor prefixes: `SQ *`, `TST*`, `PAYPAL *`, `AMZN MKTP US*`, etc.
- Transaction IDs: 4+ digit numeric sequences
- URLs: `HELP.UBER.COM`, `GO.PAYPAL.COM`
- Trailing city/state: `SAN FRANCISCO CA`, `MUMBAI MH`

### Stage 2: Alias table (`merchant_aliases.json`)

Substring match against `merchant_aliases.json` in the bundle. Returns canonical name + confidence 0.92.

### Stage 3: Fuzzy fallback (`MerchantNormalizer.fuzzyMatch`)

Token presence check against a hardcoded list of common merchants. Confidence 0.65.

### Stage 4: Rule-based fallback

Title-cases the cleaned description. Confidence 0.50.

---

## Training Data Schema

CSV with these columns:

| Column | Required | Description |
|--------|----------|-------------|
| id | ✓ | Unique row identifier |
| date | ✓ | Transaction date (YYYY-MM-DD) |
| amount | ✓ | Amount (negative = credit) |
| currency | ✓ | ISO 4217 currency code |
| raw_description | ✓ | Original bank description |
| merchant_name | | Extracted merchant |
| canonical_merchant | | Canonical name |
| mcc | | Merchant Category Code |
| account_type | | bank_account, credit_card, etc. |
| institution | | Bank/institution name |
| user_category | ✓ | Top-level category ID |
| user_subcategory | | Subcategory ID |
| is_transfer | ✓ | true/false |
| is_income | ✓ | true/false |
| source | ✓ | Parser source identifier |

See `fixtures/sample_transactions.csv` for a minimal example (NOT production data).

---

## Training & Validation Commands

```bash
# From tools/transaction-intelligence/
pip install -r requirements.txt

# Validate data schema and completeness
python validate_data.py --data /path/to/transactions.csv

# Generate training metrics (does NOT export CoreML model)
python train.py --data /path/to/transactions.csv --output results/

# Show training data statistics
python evaluate.py --data /path/to/transactions.csv
```

Make targets (from repo root):
```bash
make intelligence-validate   # Validate fixture data schema
make intelligence-train      # Generate training metrics
make intelligence-test       # Run Swift tests
```

NOTE: CoreML export is NOT performed. FinanceOS uses on-device learning
(LocalTransactionLearner k-NN + RuleBasedCategorizer) for predictions.

---

## Training Output

After running `train.py`:
```
results/
├── training_report.json          # Metrics only (no model artifact)
├── evaluation/
│   └── category_metrics.json     # Per-class accuracy, F1, confusion matrix
```

The training pipeline does NOT export CoreML models. Instead:
- Swift uses LocalTransactionLearner (k-NN on user corrections)
- Swift uses RuleBasedCategorizer (deterministic rules)
- Future: CoreML support can be added if needed via conditional bundling

---

## Evaluation Metrics

`evaluation/category_metrics.json` contains:
- `accuracy`: test set accuracy
- `macro_f1`: macro-averaged F1 across test categories
- `top3_accuracy`: fraction where correct category is in top 3 predictions
- `confusion_matrix`: N×N matrix
- `per_class`: precision, recall, F1 per category
- `class_distribution`: count per label in training set

These metrics are for validation only. They do NOT represent production model
performance—FinanceOS accuracy depends on the on-device learning algorithms
(LocalTransactionLearner) trained at runtime from user corrections.

---

## App Integration

The package is `Packages/FinanceIntelligence/`. Add it to your Xcode target.

```swift
// Instantiate (async because CoreML model loads asynchronously)
let service = await TransactionIntelligenceServiceImpl(configuration: .default)

// Analyze a single transaction
let result = try await service.analyze(transaction, context: .empty)
print(result.merchantCandidate.canonicalName)   // "Starbucks"
print(result.categoryPrediction.categoryId)      // "dining"
print(result.categoryPrediction.confidence)      // 0.9

// Analyze a batch
let results = try await service.analyzeBatch(transactions, context: .empty)

// Generate insights
let insights = try await service.generateInsights(for: transactions)
```

For ledger context:
```swift
let context = IntelligenceContext(ledgerKind: .creditCard, institution: "Amex")
let result = try await service.analyze(transaction, context: context)
```

---

## Correction Loop

When a user corrects a category or merchant:

```swift
try await correctionStore.record(
    transactionId: transaction.id,
    originalCategory: prediction.categoryId,
    correctedCategory: "groceries",
    originalMerchant: prediction.merchantCandidate.canonicalName,
    correctedMerchant: "D-Mart",
    originalConfidence: prediction.confidence,
    modelVersion: prediction.modelVersion
)
```

Corrections are persisted to disk and applied on subsequent `analyze()` calls with confidence 1.0.

To export corrections as training data:
```swift
let corrections = await correctionStore.exportTrainingEligible()
// Serialize and append to your training CSV
```

---

## Known Limitations & Future Work

1. **Small fixture dataset**: The bundled fixture CSV has 20 rows — insufficient for meaningful statistics. Use real anonymized data for actual validation.
2. **English-only descriptions**: MerchantTextCleaner handles ASCII city/state noise; Indian city names (in Devanagari) are not handled.
3. **No MCC usage**: MCC is extracted in the training schema but not yet used in `RuleBasedCategorizer`. Should be incorporated.
4. **Alias table coverage**: `merchant_aliases.json` covers ~40 merchants. Expand before shipping.
5. **No hierarchical categorization**: LocalTransactionLearner + RuleBasedCategorizer predict top-level category only. Subcategories returned as nil.
6. **No CoreML integration**: Swift side does not use CoreML models. Future work to add optional Core ML fallback if classification accuracy becomes critical.

---

## Next Steps

- [ ] Expand `merchant_aliases.json` with 200+ merchants covering Indian and global banks
- [ ] Train on real anonymized data and validate accuracy targets
- [ ] Copy trained `.mlpackage` to Resources and rebuild
- [ ] Add `AppContainer.intelligenceService` and inject into `TransactionImportPipeline`
- [ ] Persist `categoryId` on `Transaction` model (database migration required)
- [ ] Build UI for displaying category + merchant in transaction list views
- [ ] Add user correction UI in transaction detail view
- [ ] Export corrections to training data pipeline
- [ ] Add MCC as a tabular feature in training pipeline
