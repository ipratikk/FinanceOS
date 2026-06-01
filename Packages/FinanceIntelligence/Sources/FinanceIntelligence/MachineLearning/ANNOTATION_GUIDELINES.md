# Person/Merchant Narration Classification Guidelines

## Overview
This document defines how to label transaction narrations as **person**, **merchant**, or **unknown** for ML training.

## Definitions

### **Person** (P2P Transfer)
A transaction where money flows between two individuals. Indicators:
- VPA is a phone number (9XXXXXXXXX@bank, 91XXXXXXXXXXX@bank)
- NEFT/IMPS/UPI with person's name (first + last name patterns)
- Remarks field contains person name
- No business suffix (Ltd, Pvt, Services, etc.)
- Common Indian person name patterns
- Transfer to known people (family members, colleagues)

**Examples:**
- "UPI-JOHN KUMAR-9051481667@upi-..."
- "NEFT CR-ICIC0-RAJESH SHARMA-REF123"
- "UPI/9876543210@ybl/lunch payment/..."

### **Merchant** (B2C Transaction)
A transaction where money flows to a business entity. Indicators:
- Business suffixes (Ltd, Pvt, Private Limited, Services, Solutions, Enterprises, LLP)
- Known merchant names (Swiggy, Amazon, Netflix, etc.)
- Payment gateway VPAs (razorpay, cashfree, paypal, etc.)
- Utility/telecom (Airtel, Jio, etc.)
- Retail/food chains (McDonald, KFC, Subway, etc.)
- Abbreviations typical of businesses (Pvt Ltd, Inc., etc.)

**Examples:**
- "UPI-AMAZON PAYMENT-amazonpay@razorpay-..."
- "NEFT DR-ICIC0-HDFC BANK LTD-..."
- "UPI-SWIGGY-swiggy@swiggypay-..."

### **Unknown**
Cannot be confidently classified as person or merchant. Use when:
- Narration is truncated or garbled
- Name could plausibly be person OR merchant
- Missing VPA info and name is ambiguous
- Special characters preventing clear parsing

**Examples:**
- "UPI-ABC-..."
- "TRANSFER TO XYZ"
- "PAYMENT REF#12345"

## Edge Cases

### Single Word Names
- "Akshay" → **Person** (common first name, no business indicator)
- "Flipkart" → **Merchant** (known brand)
- "Sharma" → **Person** (typically surname, used alone in NEFT)
- "Solutions" → **Merchant** (almost always suffix, alone indicates business)

### Person Names with Initials
- "R K SHARMA" → **Person** (first+last pattern)
- "SHARMA AND ASSOCIATES" → **Merchant** (business indicator)

### Ambiguous Cases
- "PVTS" (if alone) → **Unknown** (could be person surname or typo)
- "12345 ENTERPRISES" → **Merchant** (clear indicator)
- "JOHN AND CO" → **Merchant** ("AND CO" indicates business partnership)

### VPA-only Decisions
- "9XXXXXXXXX@bank" → **Person** (phone number = person)
- "merchant@razorpay" → **Merchant** (gateway VPA)
- "name@ybl" → Depends on name part (phone = person, word = check name)

## Quality Assurance

1. **Confidence**: Only label if ≥80% confident
2. **Unknown Bias**: Prefer **unknown** over a weak guess
3. **Context**: Use VPA + name + bank together
4. **Consistency**: Review similar patterns before labeling batches
5. **No PII Storage**: Never store full phone numbers or real person names; hash if needed

## Sources of Examples

### Parser Fixtures (High Quality)
- Real bank statements from test data
- Extracted narrations already parsed
- High confidence labels possible from statement type

### User Corrections
- Implicit signals from FeedbackStore
- Users corrected merchant names → likely **merchant**
- Users merged people → likely **person**
- Feedback source provides context

### Synthetic
- Generated patterns for underrepresented cases
- Must follow realistic formats
- Clearly marked as synthetic source

## Labeling Workflow

1. **Extract** narration from source
2. **Anonymize** PII (hash phone numbers)
3. **Assess VPA** if present (phone = person decision)
4. **Check keywords** against known lists
5. **Evaluate pattern** (name structure, suffixes)
6. **Assign label** or mark **unknown**
7. **Document source** (fixture, feedback, synthetic)

## Statistics Target

- **Total**: ≥5,000 labeled examples
- **Balance**: ~35% person, ~50% merchant, ~15% unknown
- **Banks**: HDFC, ICICI, Axis, SBI, AMEX
- **Sources**: Mix of parser fixtures, user corrections, synthetic
