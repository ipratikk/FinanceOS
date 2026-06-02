---
doc: 011-dataset-schema
version: 0.1.0
status: Draft
date: 2026-06-02
---

# 011 — Dataset Schema

## Purpose

Define the canonical schema for every training dataset used by the FinanceOS Financial Intelligence Platform. Each schema entry specifies column names, types, constraints, example rows, class distribution targets, and required minimum sizes. These schemas are the contract between the data generation pipeline (doc 010) and the model training scripts (docs 012–018).

---

## Architecture

```
datasets/
├── merchant_training.csv
├── category_training.csv
├── intent_training.csv
├── recurring_training.csv
├── subscription_training.csv
├── income_training.csv
├── link_prediction_training.csv
├── anomaly_training.csv
├── transaction_description_training.jsonl
├── insight_generation_training.jsonl
└── embedding_training.jsonl
```

---

## 1. merchant_training.csv

**Purpose:** Train the merchant recognition model (doc 012).

### Schema

| Column | Type | Nullable | Constraint |
|--------|------|----------|------------|
| `narration` | str | No | len ∈ [3, 120] |
| `canonical_merchant` | str | No | must be in merchants.yaml |
| `bank` | str | No | e.g., HDFC, ICICI, SBI, Axis, Kotak, Unknown |
| `channel` | str | No | UPI/IMPS/NEFT/RTGS/Card/NACH/ECS/AutoPay |
| `amount_range` | str | No | low/medium/high/very_high |
| `is_unknown` | bool | No | True if canonical_merchant = "Unknown" |

Amount range buckets:
- `low`: ₹1 – ₹500
- `medium`: ₹500 – ₹5,000
- `high`: ₹5,000 – ₹50,000
- `very_high`: ₹50,000+

### Example Rows

```csv
narration,canonical_merchant,bank,channel,amount_range,is_unknown
UPI-ZEPTO MARKETPLACE-7182736,Zepto,HDFC,UPI,low,false
UPI/Swiggy/8273645,Swiggy,ICICI,UPI,medium,false
NEFT-AMAZON SELLER SERVICES PVT LTD-REF918273,Amazon,SBI,NEFT,medium,false
IMPS/927364/ZOMATO ONLINE,Zomato,Axis,IMPS,low,false
UPI-PAYTM PAYMENTS BANK-0019283,Paytm,Kotak,UPI,medium,false
UPI-LOCAL KIRANA STORE-1827364,Unknown,Unknown,UPI,low,true
```

### Class Distribution Targets

| Metric | Target |
|--------|--------|
| Minimum rows | 200,000 |
| Unique canonical merchants | ≥ 120 |
| Unknown merchant fraction | 10–15% |
| Max rows per merchant | 5,000 |
| Min rows per merchant | 200 |
| Channel balance (each) | ≥ 5% |

---

## 2. category_training.csv

**Purpose:** Train the category + subcategory classifier (doc 013).

### Schema

| Column | Type | Nullable | Constraint |
|--------|------|----------|------------|
| `narration` | str | No | len ∈ [3, 120] |
| `merchant` | str | Yes | canonical merchant or null |
| `amount` | float | No | > 0 |
| `category` | str | No | see category taxonomy |
| `subcategory` | str | Yes | see taxonomy |
| `channel` | str | No | UPI/IMPS/NEFT/RTGS/Card/NACH/ECS/AutoPay |
| `direction` | str | No | debit/credit |
| `bank` | str | No | bank identifier |

### Category Taxonomy

```
Food
  ├── Dining
  └── Food Delivery
Groceries
  ├── Online Grocery
  └── Supermarket
Rent
  └── Housing
Salary
  ├── Monthly Salary
  └── Bonus
Insurance
  ├── Life
  ├── Health
  └── Vehicle
Travel
  ├── Flights
  ├── Hotels
  ├── Cab
  └── Train/Bus
Utilities
  ├── Electricity
  ├── Mobile
  └── Broadband
Shopping
  ├── Online Shopping
  └── Clothing
Entertainment
  ├── OTT
  └── Gaming
Investments
  ├── Mutual Fund/SIP
  ├── Stocks
  └── Fixed Deposit
Transfers
  ├── Peer Transfer
  └── Self Transfer
Credit Card Payments
Loans
  ├── Home Loan EMI
  └── Personal Loan
Healthcare
  ├── Pharmacy
  └── Hospital
Education
  ├── Tuition
  └── Courses
Fuel
Personal Care
  └── Salon/Spa
Subscriptions
  └── SaaS/Apps
Dining
EMI
  └── Consumer Goods
```

### Example Rows

```csv
narration,merchant,amount,category,subcategory,channel,direction,bank
UPI-ZOMATO-8273645,Zomato,450.0,Food,Food Delivery,UPI,debit,HDFC
NEFT-HDFC BANK-SALARY CREDIT,,85000.0,Salary,Monthly Salary,NEFT,credit,HDFC
UPI-BESCOM-ELECTRICITY-9182736,BESCOM,2100.0,Utilities,Electricity,UPI,debit,SBI
NACH/LIC PREMIUM/827364,,8500.0,Insurance,Life,NACH,debit,ICICI
UPI-ZEPTO MARKETPLACE-71827,,847.0,Groceries,Online Grocery,UPI,debit,Axis
UPI-GROWW MUTUAL FUND-82736,Groww,5000.0,Investments,Mutual Fund/SIP,UPI,debit,HDFC
UPI-CRED CLUB-918273,Cred,12500.0,Credit Card Payments,,UPI,debit,HDFC
```

### Class Distribution Targets

| Metric | Target |
|--------|--------|
| Minimum rows | 250,000 |
| Unique categories | 20 |
| Min rows per category | 2,000 |
| Max category imbalance ratio (max/min count) | ≤ 10× |
| Credit rows | 15–25% |
| Debit rows | 75–85% |

---

## 3. intent_training.csv

**Purpose:** Train the intent classifier (doc 014).

### Schema

| Column | Type | Nullable | Constraint |
|--------|------|----------|------------|
| `narration` | str | No | len ∈ [3, 120] |
| `merchant` | str | Yes | canonical merchant or null |
| `amount` | float | No | > 0 |
| `direction` | str | No | debit/credit |
| `intent` | str | No | see intent taxonomy |
| `channel` | str | No | channel type |
| `bank` | str | No | bank identifier |

### Intent Taxonomy (22 intents)

```
salary                  — employer salary credit
rent                    — housing rent payment
credit_card_payment     — paying credit card bill
investment              — SIP/stocks/FD/RD purchase
insurance               — premium payment
loan_payment            — EMI/loan repayment
peer_transfer           — P2P money transfer
subscription            — recurring digital subscription
refund                  — merchant refund credit
cashback                — cashback/reward credit
income                  — non-salary income (freelance, etc.)
grocery                 — grocery purchase
food                    — food delivery / dining
fuel                    — fuel/petrol/diesel
travel                  — flights/hotels/cabs
utilities               — electricity/water/gas/mobile/internet
education               — school fees, courses, coaching
healthcare              — medical/pharmacy/hospital
entertainment           — movies/events/gaming
emi_payment             — consumer goods EMI
cash_withdrawal         — ATM withdrawal
self_transfer           — own account transfer
```

### Example Rows

```csv
narration,merchant,amount,direction,intent,channel,bank
NEFT-INFOSYS LTD-SALARY,,95000.0,credit,salary,NEFT,HDFC
UPI-CRED CLUB-182736,Cred,15000.0,debit,credit_card_payment,UPI,ICICI
UPI-ZEPTO MARKETPLACE-91827,Zepto,650.0,debit,grocery,UPI,Axis
UPI-SWIGGY-81927,Swiggy,380.0,debit,food,UPI,HDFC
UPI-GROWW-712836,Groww,2000.0,debit,investment,UPI,HDFC
UPI-JOHN DOE-091827,,5000.0,debit,peer_transfer,UPI,SBI
NACH-HDFC ERGO-HEALTH,,12000.0,debit,insurance,NACH,ICICI
UPI-NETFLIX-INDIA-71826,Netflix,649.0,debit,subscription,UPI,Kotak
REFUND-AMAZON-ORDER 9182,,450.0,credit,refund,NEFT,HDFC
```

### Class Distribution Targets

| Metric | Target |
|--------|--------|
| Minimum rows | 200,000 |
| Unique intents | 22 |
| Min rows per intent | 1,500 |
| Max intent imbalance ratio | ≤ 8× |

---

## 4. recurring_training.csv

**Purpose:** Train the recurring detection model (doc 015).

### Schema

| Column | Type | Nullable | Constraint |
|--------|------|----------|------------|
| `transaction_group` | JSON str | No | array of transaction objects |
| `cadence` | str | No | monthly/weekly/yearly/quarterly/irregular/none |
| `interval_days` | float | Yes | null for none/irregular |
| `confidence` | float | No | 0.0–1.0 |
| `merchant` | str | Yes | canonical merchant |
| `amount_mean` | float | No | > 0 |
| `amount_std` | float | No | ≥ 0 |
| `n_transactions` | int | No | ≥ 3 |

### Transaction Object Schema (within JSON array)

```json
{
  "date": "2026-01-15",
  "amount": 649.0,
  "narration": "UPI-NETFLIX-INDIA-71826",
  "direction": "debit"
}
```

### Example Rows

```csv
transaction_group,cadence,interval_days,confidence,merchant,amount_mean,amount_std,n_transactions
"[{""date"":""2025-10-15"",""amount"":649.0,...},{""date"":""2025-11-15"",""amount"":649.0,...},{""date"":""2025-12-15"",""amount"":649.0,...}]",monthly,30.0,0.97,Netflix,649.0,0.0,3
"[{""date"":""2025-10-01"",""amount"":85000.0,...},{""date"":""2025-11-01"",""amount"":85000.0,...}]",monthly,30.2,0.95,,85000.0,0.0,2
"[{""date"":""2025-09-12"",""amount"":230.0,...},{""date"":""2025-10-05"",""amount"":180.0,...},{""date"":""2025-11-20"",""amount"":310.0,...}]",none,,0.12,,240.0,65.0,3
```

### Class Distribution Targets

| Metric | Target |
|--------|--------|
| Minimum groups | 50,000 |
| Monthly cadence | 40% |
| Weekly cadence | 10% |
| Yearly cadence | 10% |
| Quarterly cadence | 10% |
| Irregular cadence | 15% |
| None | 15% |
| Min group size (n_transactions) | 3 |
| Max group size | 24 (2 years monthly) |

---

## 5. subscription_training.csv

**Purpose:** Binary classification — is this transaction a subscription?

### Schema

| Column | Type | Nullable | Constraint |
|--------|------|----------|------------|
| `narration` | str | No | len ∈ [3, 120] |
| `merchant` | str | Yes | canonical merchant |
| `amount` | float | No | > 0 |
| `is_subscription` | bool | No | |
| `service_type` | str | Yes | OTT/Music/SaaS/Gaming/Gym/Insurance/Utility/null |
| `channel` | str | No | |
| `direction` | str | No | always debit for subscriptions |

### Example Rows

```csv
narration,merchant,amount,is_subscription,service_type,channel,direction
UPI-NETFLIX-INDIA-71826,Netflix,649.0,true,OTT,UPI,debit
UPI-SPOTIFY-91827,Spotify,119.0,true,Music,UPI,debit
UPI-SWIGGY-INSTAMART-82736,Swiggy Instamart,450.0,false,,UPI,debit
NACH-HDFC LIFE INS-912736,,15000.0,true,Insurance,NACH,debit
UPI-YOUTUBE PREMIUM-819273,,189.0,true,OTT,UPI,debit
UPI-AMAZON-ORDER-718264,Amazon,2399.0,false,,UPI,debit
```

### Class Distribution Targets

| Metric | Target |
|--------|--------|
| Minimum rows | 30,000 |
| Positive (is_subscription=true) | 35–40% |
| Negative (is_subscription=false) | 60–65% |

---

## 6. income_training.csv

**Purpose:** Classify income type for credit transactions.

### Schema

| Column | Type | Nullable | Constraint |
|--------|------|----------|------------|
| `narration` | str | No | len ∈ [3, 120] |
| `amount` | float | No | > 0 |
| `income_type` | str | No | salary/bonus/refund/interest/cashback/rental/dividend/freelance/other |
| `bank` | str | No | |
| `channel` | str | No | |

### Example Rows

```csv
narration,amount,income_type,bank,channel
NEFT-INFOSYS LTD-SALARY CREDIT,95000.0,salary,HDFC,NEFT
NEFT-WIPRO LTD-BONUS Q3,45000.0,bonus,ICICI,NEFT
REFUND AMAZON IN ORDER 71826,450.0,refund,HDFC,NEFT
INT CREDITED ON SAVING A/C,1250.0,interest,SBI,internal
CASHBACK CRED REWARDS,180.0,cashback,Axis,UPI
RENT RECEIVED FROM TENANT,18000.0,rental,HDFC,NEFT
DIVIDEND-HDFC MF-FOLIO 71826,3200.0,dividend,HDFC,NEFT
UPI-RAZORPAY-FREELANCE PMT,15000.0,freelance,ICICI,UPI
```

### Class Distribution Targets

| Metric | Target |
|--------|--------|
| Minimum rows | 50,000 |
| Salary | 40% |
| Bonus | 8% |
| Refund | 15% |
| Interest | 10% |
| Cashback | 10% |
| Rental | 5% |
| Dividend | 4% |
| Freelance | 5% |
| Other | 3% |

---

## 7. link_prediction_training.csv

**Purpose:** Train the link prediction model (doc 016).

### Schema

| Column | Type | Nullable | Constraint |
|--------|------|----------|------------|
| `tx1_features` | JSON str | No | transaction feature object |
| `tx2_features` | JSON str | No | transaction feature object |
| `link_type` | str | No | see link taxonomy |
| `confidence` | float | No | 0.0–1.0 (1.0 for synthetic positive pairs) |
| `time_delta_days` | float | No | tx2.date - tx1.date |
| `amount_ratio` | float | No | tx2.amount / tx1.amount |

### Transaction Feature Object Schema

```json
{
  "narration": "NEFT-INFOSYS LTD-SALARY",
  "amount": 95000.0,
  "direction": "credit",
  "category": "Salary",
  "intent": "salary",
  "merchant": null,
  "channel": "NEFT",
  "date": "2026-01-01"
}
```

### Link Taxonomy

```
salary→rent
salary→sip
salary→insurance
salary→credit_card_payment
salary→emi
credit→withdrawal
refund→original_purchase
no_link               — negative pairs
```

### Example Rows

```csv
tx1_features,tx2_features,link_type,confidence,time_delta_days,amount_ratio
"{""narration"":""NEFT-INFOSYS-SALARY"",""amount"":95000,...}","{""narration"":""UPI-HDFC CREDIT CARD"",""amount"":12000,...}",salary→credit_card_payment,1.0,3.0,0.126
"{""narration"":""NEFT-WIPRO-SALARY"",""amount"":85000,...}","{""narration"":""NEFT-LANDLORD-RENT"",""amount"":20000,...}",salary→rent,1.0,2.0,0.235
"{""narration"":""REFUND AMAZON ORDER"",""amount"":450,...}","{""narration"":""AMAZON ORDER 82736"",""amount"":450,...}",refund→original_purchase,1.0,15.0,1.0
"{""narration"":""UPI-ZEPTO"",""amount"":350,...}","{""narration"":""UPI-SWIGGY"",""amount"":420,...}",no_link,0.0,1.0,1.2
```

### Class Distribution Targets

| Metric | Target |
|--------|--------|
| Minimum rows | 100,000 |
| Positive pairs (linked) | 50% |
| Negative pairs (no_link) | 50% |
| Per link_type (positive) | ≥ 5,000 rows each |

---

## 8. anomaly_training.csv

**Purpose:** Train the anomaly detection model (doc 017).

### Schema

| Column | Type | Nullable | Constraint |
|--------|------|----------|------------|
| `transaction_features` | JSON str | No | transaction feature object |
| `historical_stats` | JSON str | No | per-category/merchant historical stats |
| `is_anomaly` | bool | No | |
| `anomaly_type` | str | Yes | null if not anomaly; else see taxonomy |
| `severity_score` | float | Yes | 0.0–1.0; null if not anomaly |
| `z_score` | float | No | z-score of amount vs. historical mean |

### Historical Stats Schema

```json
{
  "category": "Food",
  "merchant": "Swiggy",
  "period_days": 90,
  "mean_amount": 380.0,
  "std_amount": 95.0,
  "mean_frequency_per_month": 8.0,
  "std_frequency_per_month": 2.0,
  "last_seen_days_ago": 3
}
```

### Anomaly Taxonomy

```
spending_spike          — amount > 3σ above historical mean
frequency_spike         — transaction count > 3σ above historical frequency
new_merchant            — merchant never seen before with high amount
duplicate_transaction   — same amount + merchant within 24h
subscription_price_hike — subscription amount increased > 10%
large_transfer          — unusually large P2P transfer
```

### Example Rows

```csv
transaction_features,historical_stats,is_anomaly,anomaly_type,severity_score,z_score
"{""narration"":""UPI-SWIGGY"",""amount"":2800,...}","{""merchant"":""Swiggy"",""mean_amount"":380,""std_amount"":95,...}",true,spending_spike,0.87,25.9
"{""narration"":""UPI-ZEPTO"",""amount"":650,...}","{""merchant"":""Zepto"",""mean_amount"":600,""std_amount"":180,...}",false,,0.0,0.28
"{""narration"":""UPI-UNKNOWN MERCHANT-91827"",""amount"":15000,...}","{""merchant"":null,""mean_amount"":null,...}",true,new_merchant,0.65,null
```

### Class Distribution Targets

| Metric | Target |
|--------|--------|
| Minimum rows | 80,000 |
| Normal (is_anomaly=false) | 75% |
| Anomalous (is_anomaly=true) | 25% |
| Per anomaly_type | ≥ 2,000 rows |

---

## 9. transaction_description_training.jsonl

**Purpose:** Fine-tune or prompt-tune local LLM for description generation (doc 018).

### Record Schema

```json
{
  "narration": "UPI-CRED CLUB-918273",
  "merchant": "Cred",
  "category": "Credit Card Payments",
  "intent": "credit_card_payment",
  "amount": 12500.0,
  "direction": "debit",
  "date": "2026-01-15",
  "description": "Credit card bill payment made via CRED for ₹12,500."
}
```

### Example Records

```jsonl
{"narration":"UPI-ZEPTO MARKETPLACE-718273","merchant":"Zepto","category":"Groceries","intent":"grocery","amount":847.0,"direction":"debit","date":"2026-01-12","description":"Grocery order from Zepto for ₹847."}
{"narration":"NEFT-INFOSYS LTD-SALARY CREDIT","merchant":null,"category":"Salary","intent":"salary","amount":95000.0,"direction":"credit","date":"2026-01-01","description":"Monthly salary of ₹95,000 credited from Infosys via NEFT."}
{"narration":"UPI-SWIGGY-82736","merchant":"Swiggy","category":"Food","intent":"food","amount":380.0,"direction":"debit","date":"2026-01-10","description":"Food delivery order from Swiggy for ₹380."}
{"narration":"NACH-LIC PREMIUM-91827","merchant":null,"category":"Insurance","intent":"insurance","amount":8500.0,"direction":"debit","date":"2026-01-05","description":"Life insurance premium of ₹8,500 auto-debited via NACH."}
{"narration":"UPI-GROWW MUTUAL FUND-71826","merchant":"Groww","category":"Investments","intent":"investment","amount":5000.0,"direction":"debit","date":"2026-01-10","description":"SIP investment of ₹5,000 in mutual fund via Groww."}
```

### Distribution Targets

| Metric | Target |
|--------|--------|
| Minimum records | 50,000 |
| Unique description patterns | ≥ 500 |
| Category coverage | All 20 categories |
| Intent coverage | All 22 intents |
| Description length | 1–2 sentences, 20–80 words |

---

## 10. insight_generation_training.jsonl

**Purpose:** Fine-tune insight generation component.

### Record Schema

```json
{
  "transactions": [
    {"narration": "...", "amount": 450.0, "category": "Food", "date": "2026-01-10"},
    ...
  ],
  "period": "2026-01",
  "insight_type": "spending_increase",
  "insight_text": "Your food delivery spending increased by 35% this month compared to last month."
}
```

### Insight Types

```
spending_increase       — category spend up vs. prior period
spending_decrease       — category spend down vs. prior period
new_recurring           — new recurring pattern detected
unusual_merchant        — first-time high-amount merchant
savings_opportunity     — category ripe for reduction
budget_alert            — approaching spend limit
salary_arrived          — salary credit detected
subscription_reminder   — upcoming subscription renewal
```

### Distribution Targets

| Metric | Target |
|--------|--------|
| Minimum records | 20,000 |
| Per insight_type | ≥ 1,500 records |
| Transactions per record | 5–50 |

---

## 11. embedding_training.jsonl

**Purpose:** Contrastive learning — train narration embeddings for semantic similarity.

### Record Schema (triplet format)

```json
{
  "anchor": "UPI-ZEPTO MARKETPLACE-71827",
  "positive": "ZEPTO.RZP/9182736",
  "negative": "UPI-SWIGGY-82736"
}
```

**Anchor:** canonical narration variant.
**Positive:** different variant of same merchant/intent.
**Negative:** narration from different merchant/intent (hard negatives preferred).

### Hard Negative Strategy

Hard negatives are semantically similar but different-intent narrations:
- Same amount range, different merchant
- Same channel prefix, different merchant
- Same category, different subcategory (Food vs. Groceries)

### Distribution Targets

| Metric | Target |
|--------|--------|
| Minimum triplets | 100,000 |
| Hard negative fraction | ≥ 40% |
| Merchant coverage in anchors | ≥ 100 merchants |
| Unique anchor patterns | ≥ 10,000 |

---

## Schema Validation

All schemas are validated by `pipeline/validate.py` at the end of each pipeline run:

```python
SCHEMA_CHECKS = {
    "merchant_training.csv": {
        "required_columns": ["narration", "canonical_merchant", "bank", "channel", "amount_range", "is_unknown"],
        "min_rows": 200_000,
        "label_column": "canonical_merchant",
        "min_label_count": 120,
        "max_null_fraction": {"narration": 0.0, "canonical_merchant": 0.0},
    },
    "category_training.csv": {
        "required_columns": ["narration", "merchant", "amount", "category", "subcategory", "channel", "direction", "bank"],
        "min_rows": 250_000,
        "label_column": "category",
        "min_label_count": 20,
        "max_null_fraction": {"narration": 0.0, "category": 0.0},
    },
    # ... same pattern for all datasets
}
```

---

## Inputs

- Generator scripts (doc 010)
- `config/merchants.yaml`, `config/categories.yaml`, `config/banks.yaml`

## Outputs

11 dataset files as defined above, all under `data/v{N}/`.

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| JSON column escaping errors in CSV | Medium | Use pandas with `quoting=csv.QUOTE_ALL` for JSON columns |
| Schema drift between generators | Medium | validate.py enforced as Makefile pre-commit step |
| JSONL record inconsistency | Low | JSON schema validation in validate.py |
| Large JSONL files in git | Medium | DVC tracking + git-lfs for files > 50MB |

## Benchmarks

Full schema validation run on all 11 datasets: < 60 seconds on 1M total rows.

## Testing Strategy

`training/tests/test_schemas.py`:
- Load each dataset from fixture path (`data/fixtures/`, 1000 rows each)
- Assert all required columns present and correctly typed
- Assert no null values in non-nullable columns
- Assert min/max row counts met (parameterized per dataset)
- Assert label column coverage (unique labels ≥ min_label_count)
