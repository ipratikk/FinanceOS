---
doc: 012-merchant-normalization
version: 0.1.0
status: Draft
date: 2026-06-02
---

# Merchant Normalization — Model 1

## Purpose

Define the complete design for the Merchant Recognition model: the problem it solves, the architecture chosen, training data requirements, feature engineering, UPI VPA handling, confidence thresholds, edge cases, and integration into the inference pipeline.

---

## Problem Statement

Indian bank transaction narrations refer to the same merchant in dozens of different ways:

| Raw Narration | Canonical Merchant |
|---|---|
| `UPI-ZEPTO` | Zepto |
| `UPI-ZEPTO MARKETPLACE PR` | Zepto |
| `ZEPTONOW` | Zepto |
| `ZEPTO.RZP` | Zepto |
| `ZEPTO MARKETPLACE` | Zepto |
| `UPI/DR/123/ZEPTO/9876@ybl` | Zepto |
| `SWIGGY INSTAMART` | Swiggy |
| `SWIGGY` | Swiggy |
| `SWIGGY FOOD ORDER` | Swiggy |
| `NEFT-SWIGGY IT PRIVATE` | Swiggy |

The current `MerchantAliasTable` covers only ~40 merchants with exact-match lookups. It cannot handle: new merchants, long-tail merchants, UPI gateway suffix variations, or partial name matches.

The goal is a model that resolves any narration to a canonical merchant name with > 95% Top-1 accuracy.

---

## Architecture

```
Raw Narration
      │
      ▼
[Preprocessing]
  • Uppercase normalize
  • UPI prefix stripping (UPI/, UPI-DR/, etc.)
  • Gateway suffix removal (@ybl, @okaxis, .rzp, etc.)
  • Reference ID removal ([0-9]{6,})
  • NEFT/IMPS prefix removal
      │
      ▼
[Feature String]
  "<cleaned_narration> <upi_vpa_domain> <payment_channel>"
      │
      ▼
[CoreML NLModel Text Classifier]
  • Architecture: fastText-style (for CoreML compatibility)
  • Or: DistilBERT fine-tuned → exported via coremltools
  • Input: feature string (max 128 tokens)
  • Output: (canonical_merchant, confidence) + top-3 alternatives
      │
      ▼
[Open-Set Detection]
  • IF max_confidence < 0.50 → return "Unknown" merchant
  • Unknown class trained explicitly with diverse unknown examples
      │
      ▼
MerchantPrediction
```

---

## UPI VPA Preprocessing

UPI VPAs contain high-signal merchant information but require normalization:

```python
UPI_PREFIXES = [
    r"UPI/[CD]R/\d+/",        # UPI/DR/123456/
    r"UPI-[CD]R-\d+-",        # UPI-DR-123456-
    r"UPI-",                   # UPI-ZEPTO
]

GATEWAY_SUFFIXES = [
    r"@ybl$", r"@oksbi$", r"@okicici$", r"@okaxis$",
    r"@paytm$", r"@ptyes$", r"@pthdfc$",
    r"@okhdfcbank$", r"@ibl$", r"@axl$",
    r"\.rzp$", r"\.gpay$",
]

def preprocess_upi_vpa(vpa: str) -> str:
    """Extract merchant hint from UPI VPA."""
    # strip phone numbers: 9876543210@ybl → ""
    if re.match(r"^\d{10}@", vpa):
        return ""
    # strip gateway suffix: zepto@ybl → "zepto"
    for suffix in GATEWAY_SUFFIXES:
        vpa = re.sub(suffix, "", vpa, flags=re.IGNORECASE)
    return vpa.strip()
```

---

## Training Data Requirements

### Dataset Structure (`merchant_training.csv`)

```csv
narration,canonical_merchant,confidence
UPI-ZEPTO MARKETPLACE PR,Zepto,high
ZEPTONOW,Zepto,high
UPI/DR/789123/SWIGGY/foodorder@swiggy,Swiggy,high
SWIGGY INSTAMART,Swiggy,high
NEFT-AMAZON SELLER SERVICES,Amazon,high
AMZN/MKTP,Amazon,high
NETFLIX.COM,Netflix,high
NETFLX,Netflix,medium
HDFC BANK UPI,Unknown,high
UPI-PAY TO 9876543210,Unknown,high
```

### Minimum Dataset Size

| Requirement | Target |
|---|---|
| Total training examples | 100,000+ |
| Minimum examples per known merchant | 50 |
| Number of known merchant classes | 500+ |
| Unknown class examples | 20,000+ |
| Synthetic augmentation ratio | 5:1 synthetic:real |

### Synthetic Augmentation per Merchant

For each canonical merchant, generate the following narration variants:

```python
VARIANT_TEMPLATES = [
    "{merchant}",
    "UPI-{merchant}",
    "UPI-{merchant} MARKETPLACE",
    "UPI-{merchant} MARKETPLACE PR",
    "UPI/DR/{ref}/{merchant}/{vpa}",
    "{merchant}.RZP",
    "{merchant}NOW",
    "NEFT-{merchant} PRIVATE LIMITED",
    "IMPS/{merchant}/{ref}",
    "{merchant} {suffix}",          # ORDER, PAYMENT, INSTAMART, etc.
    "{merchant} {location}",        # ZEPTO BENGALURU, SWIGGY DELHI
]

def generate_variants(merchant: str) -> list[str]:
    ref = str(random.randint(100000, 999999))
    vpa = f"{merchant.lower().replace(' ', '')}@ybl"
    suffix = random.choice(["ORDER", "PAYMENT", "FOOD", "INSTAMART", "EXPRESS"])
    location = random.choice(["BENGALURU", "MUMBAI", "DELHI", "HYDERABAD", "PUNE"])
    return [t.format(merchant=merchant, ref=ref, vpa=vpa,
                     suffix=suffix, location=location)
            for t in VARIANT_TEMPLATES]
```

---

## Merchant Taxonomy

Top-level merchant categories for dataset stratification:

| Category | Example Merchants |
|---|---|
| Quick Commerce | Zepto, Blinkit, Swiggy Instamart, BigBasket Now, Dunzo |
| Food Delivery | Swiggy, Zomato |
| E-Commerce | Amazon, Flipkart, Meesho, Myntra, Ajio, Nykaa |
| Travel | MakeMyTrip, Yatra, Goibibo, IRCTC, OYO, EaseMyTrip |
| Streaming | Netflix, Hotstar, ZEE5, SonyLIV, JioCinema, Amazon Prime |
| Cab/Mobility | Ola, Uber, Rapido, Namma Yatri |
| Finance | Zerodha, Groww, Upstox, INDmoney, Kuvera |
| Insurance | LIC, HDFC Life, ICICI Prudential, Star Health |
| Utilities | BESCOM, BWSSB, Airtel, Jio, BSNL, ACT Fibernet |
| Pharmacy | Pharmeasy, 1mg, Netmeds, Apollo Pharmacy |
| Gaming | MPL, Dream11, My11Circle |
| Food (Offline) | Café Coffee Day, McDonald's, Domino's, Pizza Hut |
| Fuel | HPCL, BPCL, Indian Oil, Reliance BP |
| Supermarkets | DMart, More, Spencer's, Reliance Fresh, Star Bazaar |
| Credit Card | Amex, HDFC Card, ICICI Card, Axis Card, SBI Card |

---

## Swift Implementation

```swift
// MerchantRecognition/CoreMLMerchantRecognizer.swift

public final class CoreMLMerchantRecognizer: MerchantRecognizer {
    private let model: NLModel
    private let preprocessor: MerchantFeatureExtractor
    private let unknownThreshold: Float = 0.50

    public init(registry: any ModelRegistry) throws {
        let mlModel = try registry.loadCoreML(.merchant)
        self.model = try NLModel(mlModel: mlModel)
        self.preprocessor = MerchantFeatureExtractor()
    }

    public func recognize(_ narration: String, upiVPA: String? = nil,
                          channel: PaymentChannel? = nil) async -> MerchantPrediction {
        let features = preprocessor.extract(narration: narration, vpa: upiVPA, channel: channel)
        let hypotheses = model.predictedLabelHypotheses(for: features, maximumCount: 3)

        guard let (topLabel, topConfidence) = hypotheses.max(by: { $0.value < $1.value }),
              Float(topConfidence) >= unknownThreshold else {
            return MerchantPrediction(canonicalName: "Unknown",
                                     confidence: 0, source: .model, alternatives: [])
        }

        let alternatives = hypotheses
            .sorted { $0.value > $1.value }
            .dropFirst()
            .prefix(2)
            .map { MerchantPrediction.MerchantCandidate(name: $0.key, confidence: Float($0.value)) }

        return MerchantPrediction(canonicalName: topLabel,
                                 confidence: Float(topConfidence),
                                 source: .model,
                                 alternatives: Array(alternatives))
    }
}
```

---

## Performance Targets

| Metric | Target |
|---|---|
| Top-1 Accuracy | ≥ 0.95 |
| Top-3 Accuracy | ≥ 0.99 |
| Unknown Merchant Detection Recall | ≥ 0.90 |
| Unknown Merchant False Positive Rate | ≤ 0.03 |
| P95 Inference Latency | < 20 ms |
| Model Size | < 20 MB |

---

## Edge Cases

| Case | Handling |
|---|---|
| Phone number as UPI VPA (`9876543210@paytm`) | Preprocess: strip numeric VPA; classify as Unknown unless narration has other signal |
| Bank-to-bank NEFT/RTGS | Classify as Unknown merchant; intent = transfer |
| ATM withdrawal | Special class: "ATM" canonical merchant |
| EMI deduction | Canonical merchant = loan provider if identifiable; else Unknown |
| International transaction | Handle romanized merchant names (e.g., NETFLIX.COM, SPOTIFY.AB) |
| Duplicate merchant names (Axis card vs. Axis mutual fund) | Use payment channel context to disambiguate |

---

## Training Script

`training/merchant/train.py`

```python
# Inputs:  datasets/merchant_training.csv
# Outputs: artifacts/MerchantRecognizer_v{version}.mlpackage

import pandas as pd
import coremltools as ct
from sklearn.model_selection import train_test_split

df = pd.read_csv("datasets/merchant_training.csv")
X_train, X_test, y_train, y_test = train_test_split(
    df["narration"], df["canonical_merchant"], test_size=0.15, stratify=df["canonical_merchant"]
)

# Train NLModel via CreateML (Python API)
# Alternatively: fine-tune DistilBERT and export via coremltools
# See training/merchant/README.md for both approaches
```

---

## Risks

| Risk | Mitigation |
|---|---|
| Indian merchant name space extremely large (millions of SMBs) | Open-set detection; Unknown class trained explicitly; high-confidence threshold |
| UPI VPA format changes with new payment apps | Extend preprocessing regex; VPA is supplementary signal, not sole input |
| Model memorizes training narrations | Data augmentation + dropout in training; evaluate on held-out real transactions |
| Merchant name collisions (Axis bank vs. Axis card vs. Axis mutual fund) | Add payment_channel as feature; category context from Model 2 as secondary |
