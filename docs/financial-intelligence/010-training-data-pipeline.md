---
doc: 010-training-data-pipeline
version: 0.1.0
status: Draft
date: 2026-06-02
---

# 010 — Training Data Pipeline

## Purpose

Define the end-to-end pipeline for generating, augmenting, deduplicating, splitting, and versioning all training datasets used by the FinanceOS Financial Intelligence Platform. All data is synthetic or privacy-scrubbed; no real user transactions are used in training. The pipeline must produce ≥ 1 million transactions across all datasets, covering the full spectrum of Indian financial channels, banks, merchants, and behavioral patterns.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    TRAINING DATA PIPELINE                           │
│                                                                     │
│  ┌─────────────┐   ┌──────────────┐   ┌──────────────────────────┐ │
│  │  Generator  │   │  Augmentor   │   │      Deduplicator        │ │
│  │  Scripts    │──▶│  (noise,     │──▶│  (exact hash +           │ │
│  │  (9 scripts)│   │   typos,     │   │   semantic near-dup)     │ │
│  │             │   │   variants)  │   │                          │ │
│  └─────────────┘   └──────────────┘   └────────────┬─────────────┘ │
│                                                     │               │
│                                          ┌──────────▼────────────┐  │
│                                          │    Train/Val/Test     │  │
│                                          │    Splitter           │  │
│                                          │    (stratified)       │  │
│                                          └──────────┬────────────┘  │
│                                                     │               │
│                                          ┌──────────▼────────────┐  │
│                                          │    DVC Versioning     │  │
│                                          │    (data/v{N}/*.csv)  │  │
│                                          └───────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘

Generator Scripts
─────────────────
generate_merchants.py          →  merchant_training.csv
generate_transactions.py       →  category_training.csv
generate_categories.py         →  category_training.csv (class balance pass)
generate_salary_patterns.py    →  income_training.csv
generate_recurring_patterns.py →  recurring_training.csv
generate_subscription_patterns.py → subscription_training.csv
generate_intent_patterns.py    →  intent_training.csv
generate_linking_examples.py   →  link_prediction_training.csv
generate_anomaly_examples.py   →  anomaly_training.csv
```

---

## Inputs

| Source | Description |
|--------|-------------|
| `config/merchants.yaml` | Canonical merchant list with categories, aliases, bank prefixes |
| `config/banks.yaml` | Bank names, UPI handles, IFSC prefixes, narration formats |
| `config/categories.yaml` | Category taxonomy (category → subcategory → intents) |
| `config/channels.yaml` | Channel types: UPI, IMPS, NEFT, RTGS, NACH, ECS, Card, AutoPay |
| `config/amount_distributions.yaml` | Per-category amount ranges (mean, std, percentiles) |

---

## Outputs

| File | Format | Min Size |
|------|--------|----------|
| `data/v{N}/merchant_training.csv` | CSV | 200,000 rows |
| `data/v{N}/category_training.csv` | CSV | 250,000 rows |
| `data/v{N}/intent_training.csv` | CSV | 200,000 rows |
| `data/v{N}/recurring_training.csv` | CSV | 50,000 groups |
| `data/v{N}/subscription_training.csv` | CSV | 30,000 rows |
| `data/v{N}/income_training.csv` | CSV | 50,000 rows |
| `data/v{N}/link_prediction_training.csv` | CSV | 100,000 pairs |
| `data/v{N}/anomaly_training.csv` | CSV | 80,000 rows |
| `data/v{N}/transaction_description_training.jsonl` | JSONL | 50,000 records |
| `data/v{N}/insight_generation_training.jsonl` | JSONL | 20,000 records |
| `data/v{N}/embedding_training.jsonl` | JSONL | 100,000 triplets |
| **Total** | | **≥ 1,130,000 records** |

---

## Interfaces

### Python Training Script Structure

```
training/
├── scripts/
│   ├── generate_merchants.py
│   ├── generate_transactions.py
│   ├── generate_categories.py
│   ├── generate_salary_patterns.py
│   ├── generate_recurring_patterns.py
│   ├── generate_subscription_patterns.py
│   ├── generate_intent_patterns.py
│   ├── generate_linking_examples.py
│   └── generate_anomaly_examples.py
├── pipeline/
│   ├── augment.py          # noise injection, typo generation, variant expansion
│   ├── deduplicate.py      # exact hash + MinHash LSH near-dup removal
│   ├── split.py            # stratified train/val/test split
│   └── validate.py         # schema validation, class distribution check
├── config/
│   ├── merchants.yaml
│   ├── banks.yaml
│   ├── categories.yaml
│   ├── channels.yaml
│   └── amount_distributions.yaml
└── Makefile                # make generate, make augment, make split, make validate
```

### Script API — Each Generator

```python
# generate_merchants.py
def generate(
    n_samples: int = 200_000,
    output_path: str = "data/raw/merchant_training.csv",
    seed: int = 42,
    config_path: str = "config/merchants.yaml",
) -> pd.DataFrame:
    """
    Returns DataFrame with columns:
      narration, canonical_merchant, bank, channel, amount_range
    Writes to output_path.
    """

# generate_transactions.py
def generate(
    n_samples: int = 250_000,
    output_path: str = "data/raw/category_training.csv",
    seed: int = 42,
) -> pd.DataFrame:
    """
    Returns DataFrame with columns:
      narration, merchant, amount, category, subcategory, channel
    """

# generate_salary_patterns.py
def generate(
    n_samples: int = 50_000,
    n_employers: int = 500,
    output_path: str = "data/raw/income_training.csv",
    seed: int = 42,
) -> pd.DataFrame:
    """
    Returns DataFrame with columns:
      narration, amount, income_type
    Salary narrations: "SALARY {EMPLOYER}", "SAL/{MONTH}", "NEFT-{EMPLOYER}-SALARY", etc.
    """

# generate_recurring_patterns.py
def generate(
    n_groups: int = 50_000,
    min_transactions_per_group: int = 3,
    max_transactions_per_group: int = 24,
    output_path: str = "data/raw/recurring_training.csv",
    seed: int = 42,
) -> pd.DataFrame: ...

# generate_subscription_patterns.py
def generate(n_samples: int = 30_000, ...) -> pd.DataFrame: ...

# generate_intent_patterns.py
def generate(n_samples: int = 200_000, ...) -> pd.DataFrame: ...

# generate_linking_examples.py
def generate(
    n_positive_pairs: int = 50_000,
    n_negative_pairs: int = 50_000,
    output_path: str = "data/raw/link_prediction_training.csv",
    seed: int = 42,
) -> pd.DataFrame: ...

# generate_anomaly_examples.py
def generate(
    n_normal: int = 60_000,
    n_anomalous: int = 20_000,
    output_path: str = "data/raw/anomaly_training.csv",
    seed: int = 42,
) -> pd.DataFrame: ...
```

### Augmentation API

```python
# pipeline/augment.py
def augment(
    df: pd.DataFrame,
    dataset_type: str,          # "merchant" | "category" | "intent" | ...
    noise_rate: float = 0.15,   # fraction of rows to apply noise
    typo_rate: float = 0.05,    # fraction of chars to corrupt
    seed: int = 42,
) -> pd.DataFrame:
    """
    Applies:
    1. Random character substitution (OCR-style: 0→O, 1→I)
    2. Extra whitespace injection
    3. UPI prefix shuffling (UPI/, upi-, UPI-)
    4. Bank prefix variants (HDFC→HDFCBANK, SBI→SBIINB)
    5. Amount jitter (±2% for regression-adjacent tasks)
    """
```

### Deduplication API

```python
# pipeline/deduplicate.py
def deduplicate(
    df: pd.DataFrame,
    text_column: str = "narration",
    exact_hash: bool = True,
    near_dup_threshold: float = 0.85,   # Jaccard threshold
    use_minhash: bool = True,
    n_permutations: int = 128,
) -> pd.DataFrame:
    """
    Stage 1: exact SHA-256 hash on (narration, label) → drop exact dups
    Stage 2: MinHash LSH on narration tokens → drop near-dups above threshold
    Returns deduplicated DataFrame with 'dup_removed' count in metadata.
    """
```

### Split API

```python
# pipeline/split.py
def split(
    df: pd.DataFrame,
    label_column: str,
    train_ratio: float = 0.80,
    val_ratio: float = 0.10,
    test_ratio: float = 0.10,
    seed: int = 42,
    min_class_samples: int = 50,    # warn if class below this in test
) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    """
    Stratified split preserving class distribution.
    Returns (train_df, val_df, test_df).
    Writes {output}/train.csv, {output}/val.csv, {output}/test.csv.
    """
```

---

## Implementation Plan

### Phase 1 — Config & Infrastructure (Week 1)

1. Author `config/merchants.yaml` — 100+ canonical merchants with:
   - `canonical_name`
   - `category`
   - `aliases: [list]`
   - `bank_prefix_variants: {HDFC: [...], ICICI: [...], ...}`
   - `upi_handles: [zepto@icici, zeptopay@ybl, ...]`
   - `amount_range: {min, max, mean, std}`

2. Author `config/banks.yaml` — 15+ banks with narration format templates:
   ```yaml
   HDFC:
     templates:
       - "UPI-{MERCHANT}-{REF}"
       - "NEFT/{PAYEE}/{REF}"
       - "IMPS/{REF}/{PAYEE}"
   ```

3. Author `config/categories.yaml` with full taxonomy and class weights.

4. Set up `Makefile` with targets: `generate`, `augment`, `dedup`, `split`, `validate`, `all`.

### Phase 2 — Core Generators (Week 2)

5. Implement `generate_merchants.py` — the most critical generator. Produces narration variants for every merchant × bank × channel combination.

6. Implement `generate_transactions.py` — draws from merchant catalog, assigns amount from distribution, assigns category from merchant lookup.

7. Implement `generate_intent_patterns.py` — derives intent from (merchant, direction, amount_bucket, channel) rules.

### Phase 3 — Specialized Generators (Week 3)

8. Implement `generate_salary_patterns.py` — generates realistic employer names (company_name patterns), salary ranges by sector.

9. Implement `generate_recurring_patterns.py` — builds transaction groups with jittered timestamps.

10. Implement `generate_subscription_patterns.py` — OTT (Netflix, Prime, Hotstar, Spotify, YouTube), SaaS, gym, insurance monthly.

11. Implement `generate_linking_examples.py` — positive pairs: salary→rent (same month), salary→SIP (same month, amount ≤ 30% of salary).

12. Implement `generate_anomaly_examples.py` — injects spike anomalies (5× normal amount), frequency anomalies (3× normal frequency), and new-merchant anomalies.

### Phase 4 — Augmentation & Pipeline (Week 4)

13. Implement `pipeline/augment.py` with all noise types.
14. Implement `pipeline/deduplicate.py` with MinHash LSH.
15. Implement `pipeline/split.py` with stratified split.
16. Implement `pipeline/validate.py` — schema checks, min class size checks, distribution reports.
17. End-to-end `make all` run producing versioned output.

### Phase 5 — Versioning (Week 4)

18. Initialize DVC: `dvc init`, add `data/` to DVC tracking.
19. Configure remote: local cache initially, S3/GCS optional later.
20. Tag dataset versions: `data/v1.0/`, `data/v1.1/`, etc.
21. Store `data/v{N}/metadata.json` — generator git SHA, config hashes, row counts, class distributions.

---

## Data Versioning Strategy

Use **DVC** (Data Version Control) alongside Git:

```
data/
├── v1.0/
│   ├── merchant_training.csv       # tracked by DVC
│   ├── category_training.csv
│   ├── ...
│   └── metadata.json               # committed to Git
├── v1.1/
│   └── ...
└── current -> v1.1/                # symlink
```

`metadata.json` schema:
```json
{
  "version": "1.1",
  "generated_at": "2026-06-02T00:00:00Z",
  "generator_git_sha": "abc123",
  "config_hashes": {
    "merchants.yaml": "sha256:...",
    "banks.yaml": "sha256:..."
  },
  "row_counts": {
    "merchant_training": 210543,
    "category_training": 255012,
    ...
  },
  "class_distributions": {
    "merchant_training": {"Zepto": 1205, "Swiggy": 1189, ...},
    "category_training": {"Food": 35200, "Groceries": 31000, ...}
  }
}
```

Git commits reference DVC `.dvc` pointer files — data itself stored in DVC cache/remote.

---

## Merchant Variant Generation Strategy

Each canonical merchant must produce sufficient variant coverage:

```python
# Example: Zepto variants
ZEPTO_VARIANTS = [
    # Direct name variants
    "ZEPTO", "Zepto", "zepto", "ZEPTONOW", "ZeptoNow",
    # Marketplace variants
    "ZEPTO MARKETPLACE", "ZEPTO MARKETPLACE PR", "ZEPTOMARKETPLACE",
    # UPI handle variants
    "ZEPTO@ICICI", "ZEPTOPAY@YBL", "ZEPTO.RZP", "ZEPTO@KOTAK",
    # Bank-prefixed UPI
    "UPI-ZEPTO-{ref}", "UPI/ZEPTO/{ref}", "UPI-ZEPTOMARKETPLACE-{ref}",
    "HDFC/UPI/ZEPTO/{ref}", "ICICI/ZEPTO/{ref}",
    # IMPS/NEFT narration variants
    "IMPS/{ref}/ZEPTO MARKETPLACE", "NEFT-ZEPTO-{ref}",
    # With noise
    "ZEPT0", "ZEPT O", "Z EPTO",  # OCR noise
]
```

Minimum 20 variants per merchant. Templates parameterized by `{ref}` (random 8-12 digit reference), `{date}`, `{amount}`.

---

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Class imbalance — common merchants dominate | High | Cap per-class at 5,000 rows; upsample rare merchants |
| Narration format staleness (banks change formats) | Medium | Config-driven templates; easy to add new formats |
| Near-duplicate leakage into test set | High | MinHash LSH dedup before split; cross-split similarity check |
| Synthetic data distribution mismatch | Medium | Validate against real narration samples (anonymized) at each release |
| DVC remote unavailable in CI | Low | Keep `data/v{N}/` in git-lfs as fallback for small datasets |
| Generator script drift across versions | Medium | Lock generator git SHA in metadata.json; reproducible seeds |

---

## Benchmarks

Target dataset properties after pipeline run:

| Metric | Target |
|--------|--------|
| Total records across all datasets | ≥ 1,130,000 |
| Merchant coverage (unique canonical) | ≥ 120 merchants |
| Merchant variant coverage (avg per merchant) | ≥ 25 variants |
| Bank coverage | ≥ 15 banks |
| Channel coverage | 8 channels (UPI/IMPS/NEFT/RTGS/Card/NACH/ECS/AutoPay) |
| Category coverage | ≥ 20 categories |
| Intent coverage | ≥ 22 intents |
| Class balance (merchant): Gini impurity | ≤ 0.15 |
| Dedup removal rate | ≤ 5% |
| Pipeline wall time (full run) | ≤ 30 minutes (single CPU) |
| Reproducibility (same seed → identical output) | 100% |

---

## Testing Strategy

```
training/tests/
├── test_generate_merchants.py      # row count, column schema, variant coverage
├── test_generate_transactions.py   # class distribution, no null narrations
├── test_augment.py                 # noise rate validation, no label corruption
├── test_deduplicate.py             # known-dup pairs removed, no false positives
├── test_split.py                   # stratification within 2% of target ratio
├── test_validate.py                # schema violations detected
└── test_pipeline_e2e.py            # full make all → metadata.json correct
```

Each generator test:
1. Runs with `n_samples=1000, seed=42` (fast)
2. Checks schema (all required columns present, correct dtypes)
3. Checks class balance (no class > 20× smallest class for balanced datasets)
4. Checks narration length (3 ≤ len ≤ 120 chars)
5. Checks no NaN in label columns

Integration test (`test_pipeline_e2e.py`):
- Runs full pipeline on `n_samples=5000` per generator
- Confirms `metadata.json` written with correct counts
- Confirms train/val/test sizes sum to total
- Confirms no narration appears in both train and test sets
