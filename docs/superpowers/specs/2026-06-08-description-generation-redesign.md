# Description Generation Redesign

**Date:** 2026-06-08
**Branch:** feat/phase-4-enrichment-FINOS-81
**Status:** Approved, pending implementation

---

## Problem

729 transactions enriched. 29% (209) have the filler phrase "transaction label" (e.g. "Ritik Gupta transaction label"). Structured bank strings like `INW 050526I049903643 USD2382.62@95.2648` generate garbled output ("Credit from Inw I Usd .62@95.") instead of structured descriptions. Salary NEFT credits (14 transactions, explicitly labeled "SALARY FOR APRIL 2025") generate "PayPal India transaction label". Multi-line outputs, LLM refusals, and prompt-echo artifacts have leaked into the database.

Root causes:
- `DescriptionContext` does not carry `rawDescription` — downstream generators cannot access the original bank string.
- `AppleIntelligenceAdapter` is called for simple personal transfers where a short name is sufficient.
- `validate()` in `AppleIntelligenceAdapter` does not reject multi-line output, LLM refusals, or prompt-echo artifacts like "transaction label" and "noun phrase".
- `FallbackGenerator.transferDescription()` adds "Payment to" / "Transfer from" prefixes that add noise for person-to-person UPI payments.

---

## Design

### Architecture: Three-tier generation

```
rawDescription + DescriptionContext
        │
        ▼
1. RawPatternParser   — deterministic regex; handles opaque bank formats
        │ nil
        ▼
2. FallbackGenerator  — intent + merchant → short clean label
        │ intent == .unknown
        ▼
3. AppleIntelligenceAdapter — AI; last resort for opaque unknown merchants
```

Tier 1 fires first on `rawDescription`. If it matches, the result is used and lower tiers are skipped. This handles all structured-but-opaque bank formats. Tiers 2 and 3 are unchanged in their responsibility boundaries.

---

### Data Model: `DescriptionContext`

Add one field:

```swift
public let rawDescription: String
```

Defaulted to `""` in the initializer so all 13 existing test callsites require no changes.

Both production callsites in `TransactionIntelligenceServiceImpl` pass `transaction.description` as `rawDescription`:
- `analyzeEnriched` (line 311)
- `generateAIDescriptions` (line 276)

---

### New: `RawPatternParser`

`public struct RawPatternParser: Sendable`

Single public method: `func parse(_ rawDescription: String, merchantName: String) -> String?`

Returns `nil` when no pattern matches. Never throws.

#### Pattern catalogue

| Pattern | Trigger | Output |
|---------|---------|--------|
| Inward remittance | `^INW\s+\S+\s+([A-Z]{3})([\d.]+)@([\d.]+)` | `Inward Remittance · $2,382.62 @ ₹95.27` |
| DPO tax charge | `DPO\w+\s+(IGST\|CGST\|SGST)` | `IGST on Wire Transfer` |
| IGST-VPS bank charge | `^(IGST\|CGST\|SGST)-VPS\S+\s+RATE\s+([\d.]+)` | `IGST · 18% on Bank Charges` |
| Interest credit | `^INTEREST\s+PAID\s+TILL\s+\d+-(JAN\|FEB\|...\|DEC)-(\d{4})` | `Bank Interest · June 2025` |
| NEFT salary | `^NEFT CR` + `SALARY FOR` anywhere in string | `Salary from PayPal India · April 2025` |

**INW formatting:** Currency symbol map: USD→$, EUR→€, GBP→£, all others→uppercase code. Rate rounded to 2 decimal places. Amount formatted with thousands separator.

**NEFT salary formatting:** Month extracted from "SALARY FOR {MONTH} {YEAR}" using a month-name→number map. Merchant name comes from `merchantName` parameter (already normalized by `MerchantNormalizer` upstream).

**Separator:** `·` (U+00B7 MIDDLE DOT) between label and detail components, matching iOS/macOS native label conventions.

UPI personal transfers are explicitly out of scope for `RawPatternParser` — handled by `FallbackGenerator` simplification.

---

### Modified: `FallbackGenerator`

Two changes only. All other templates unchanged.

**1. `transferDescription()` with no relationship — drop directional prefix:**

```
Before: "Payment to Ritik Gupta"  (debit)
        "Transfer from Seema Goel" (credit)
After:  "Ritik Gupta"
```

Direction is already shown by the UI (amount sign, debit/credit indicator). The name alone is sufficient.

**2. Relationship label tightening:**

| Relationship | Before | After |
|---|---|---|
| `.landlord` | `Rent payment to {name}` | `House Rent · {name}` |
| `.employer` | `Salary from {name}` | `Salary · {name}` |
| `.family` | `Family transfer — {name}` | `{name}` |
| `.friend` | `Transfer to {name}` | `{name}` |
| `.reimbursement` | `Reimbursement from {name}` | `Reimbursement from {name}` (no change) |

---

### Modified: `AppleIntelligenceAdapter`

**Fix 1 — Multi-line rejection.** Take only the first non-empty line from the model response before validation:

```swift
let text = response.content
    .components(separatedBy: .newlines)
    .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? ""
```

Eliminates the "Sachin merchandise\n\nSachin collectibles\n..." class of bugs.

**Fix 2 — Expanded `promptEchoMarkers`.** Add to the existing list:

```swift
"transaction label",
"i apologize",
"cannot assist",
"merchant name:",
"noun phrase",
"transaction label is",
"is a noun phrase"
```

Eliminates stored LLM refusals, prompt-echo artifacts, and the dominant "transaction label" filler class.

**Fix 3 — Minimum word count.** Reduce from 3 → 2. Allows clean 2-word outputs (e.g. "Apple Subscription") if generated. Previously, the 3-word minimum caused the model to pad with "transaction label" to meet the floor.

---

### Modified: `DescriptionGenerator`

Add Tier 1 call at the top of the generation chain. Both `generate(from:)` and `generateSync(from:)` check `RawPatternParser` first:

```swift
if let parsed = rawPatternParser.parse(context.rawDescription, merchantName: context.merchantName) {
    return parsed
}
```

`DescriptionGenerator` gains a `rawPatternParser: RawPatternParser` property (initialized in `init()`).

---

## Files

| File | Change type |
|------|-------------|
| `DescriptionGeneration/RawPatternParser.swift` | New |
| `DescriptionGeneration/DescriptionContext.swift` | Add `rawDescription: String = ""` |
| `DescriptionGeneration/DescriptionGenerator.swift` | Prepend Tier 1; add `rawPatternParser` property |
| `DescriptionGeneration/FallbackGenerator.swift` | Simplify `transferDescription()` + relationship labels |
| `DescriptionGeneration/AppleIntelligenceAdapter.swift` | Validation hardening (3 fixes) |
| `Categorization/TransactionIntelligenceServiceImpl.swift` | Pass `rawDescription` at both callsites |
| `Tests/DescriptionGeneratorTests.swift` | Update transfer assertions; add `RawPatternParser` tests |

No changes to `RuleBasedCategorizer`, `UPIDescriptionParser`, or `MerchantNormalizer`.

---

## Test coverage

`RawPatternParser` tests cover:
- Each of the 5 patterns with real examples from the database
- Edge cases: missing rate in INW, unknown currency code, SGST vs CGST vs IGST
- Nil return for unrecognized format

`FallbackGenerator` tests update:
- Transfer with no relationship: assert output == `merchantName` (not "Payment to X")
- Landlord relationship: assert `"House Rent · X"`

`AppleIntelligenceAdapter` validation tests update:
- Multi-line input → only first line used
- "transaction label" → rejected
- "I apologize, but I cannot assist" → rejected
- 2-word output → accepted

---

## Out of scope

- Fixing `RuleBasedCategorizer` to correctly classify Seema Goel rent as housing (categorizer correctness is a separate concern)
- Fixing `generateAIDescriptions` to use the full classified intent (not just `.unknown`) — deferred
- ACH SIP pattern (already produces acceptable "SIP Mutual Fund" output)
- Deduplicating existing bad descriptions in the DB (separate re-run task)
