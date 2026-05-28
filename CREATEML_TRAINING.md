# CreateML Tabular Classifier Training

## Data Ready
- **File**: `/tmp/hdfc_training_tabular.csv`
- **Rows**: 432 real HDFC transactions
- **Features**: description, amount_cents, is_income, is_debit
- **Target**: label (7 categories)

## Step-by-Step in Xcode

### 1. Open Xcode
```bash
open -a Xcode
```

### 2. Create ML Project
- **File** → **New** → **ML Models**
- Select **Tabular Classifier**
- Click **Next**

### 3. Import Training Data
- Under "Training Data", click folder icon
- Navigate to `/tmp/hdfc_training_tabular.csv`
- Click **Open**
- Xcode auto-detects columns

### 4. Verify Feature Configuration
CreateML should show:
```
Features:
  - description (Text)
  - amount_cents (Numeric)
  - is_income (Numeric)
  - is_debit (Numeric)

Target:
  - label (Classification)
```

If wrong, click **Edit** → adjust mapping

### 5. Configure Training
Leave defaults OR set:
- **Algorithm**: Automatic (recommended)
- **Training Iterations**: 100-200
- **Validation**: Auto-split (80% train, 20% validate)

### 6. Train
- Click **Train** button
- Wait 30-60 seconds
- Watch progress bar

### 7. Evaluate Results
After training:
- **Accuracy**: Shows % correct predictions
- **Precision/Recall**: Per-category metrics
- **Confusion Matrix**: Where model confuses categories

**Target**: Accuracy ≥ 0.85

### 8. Export Model
- Top-right: Click **Get Model**
- Xcode saves to: `~/Downloads/TransactionCategoryClassifier.mlmodel`

### 9. Bundle in App
```bash
cp ~/Downloads/TransactionCategoryClassifier.mlmodel \
   /Users/pragoel/Documents/GitHub/FinanceOS/Packages/FinanceIntelligence/Sources/FinanceIntelligence/Resources/

# Verify
ls -lh Packages/FinanceIntelligence/Sources/FinanceIntelligence/Resources/TransactionCategoryClassifier.mlmodel
```

### 10. Build & Test
```bash
cd /Users/pragoel/Documents/GitHub/FinanceOS
swift build
cd Packages/FinanceIntelligence && swift test
```

---

## Expected Model Inputs (CreateML)

When you export, model will accept:
```swift
input: {
  "description": String,     // cleaned transaction description
  "amount_cents": Int64,     // absolute amount in cents
  "is_income": Double,       // 0 or 1
  "is_debit": Double         // 0 or 1
}

output: {
  "label": String,                // predicted category
  "labelProbabilities": [String: Double]  // confidence scores
}
```

### Use in Swift
```swift
let input = TransactionCategoryClassifierInput(
    description: "zepto marketplace",
    amount_cents: 79900,
    is_income: 0,
    is_debit: 1
)
let output = try model.prediction(input: input)
print(output.label)  // "groceries"
print(output.labelProbabilities)  // ["groceries": 0.95, ...]
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Column not found" | Verify CSV has exact column names: `description`, `amount_cents`, `is_income`, `is_debit`, `label` |
| Low accuracy (<60%) | Check label distribution—try adding more data or removing rare categories |
| Model won't load in Swift | Ensure `.mlmodel` file copied to Resources/ folder, not in subdirectory |
| "Unknown feature" error | Check feature names match CreateML configuration exactly |

---

## After Training

Once model loads in app:
1. CoreMLCategorizer.swift will automatically detect it
2. TransactionIntelligenceServiceImpl will use it as Priority #2 (after LocalTransactionLearner)
3. Falls back to RuleBasedCategorizer if model errors

---

## Next: Integration

Once `.mlmodel` is in Resources:
- App bundles it automatically (Package.swift configured)
- CoreMLCategorizer loads on startup
- First prediction: slower (model load), then cached
- User corrections still train LocalTransactionLearner for future priority

---

Done. Ready to train in Xcode.
