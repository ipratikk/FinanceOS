---
doc: 018-description-generation
version: 0.1.0
status: Draft
date: 2026-06-02
---

# Description Generation — Model 10

## Purpose

Define the complete design for the Description Generation model. Transaction descriptions transform raw bank narrations into human-readable, contextual financial descriptions. Where a raw narration is `UPI-CRED CLUB-9876543210@ybl`, the description is `Credit card bill payment via CRED for ₹12,500`. This powers: the transaction list view, notification summaries, financial reports, and the agent's conversational responses about specific transactions.

---

## Problem Statement

### Current State

1. `AppleIntelligenceAdapter` — calls Apple Writing Tools API (iOS 18.1+/macOS 15.1+ only)
2. `FallbackGenerator` — template-based: `"{merchant} payment via {channel} for {amount}"`

`FallbackGenerator` output is robotic and context-free. It says the same thing for every Swiggy transaction regardless of whether it's groceries, food delivery, or a refund.

### Target State

```
Input:  narration="UPI-SWIGGY INSTAMART", merchant="Swiggy", category=groceries,
        amount=₹849, direction=debit, date=2026-05-15 (Saturday 8:30 PM)

Output: "Grocery order from Swiggy Instamart for ₹849 on Saturday evening."

Input:  narration="NEFT-SALARY FROM ACME CORP", direction=credit, amount=₹85,000

Output: "Monthly salary credit of ₹85,000 from Acme Corp."

Input:  narration="AMAZON.IN REFUND", direction=credit, amount=₹1,299

Output: "Refund of ₹1,299 from Amazon received."
```

---

## Architecture: Fallback Chain

```
[1] Apple Intelligence (on-device LLM via WritingTools API)
        │ available: iOS 18.1+ / macOS 15.1+, device supports Apple Intelligence
        │ unavailable ↓
[2] MLX Local LLM (Phi-3 Mini or Qwen3 4B, on-device)
        │ available: device has ≥ 6 GB RAM, thermal state nominal
        │ unavailable ↓
[3] FallbackGenerator (template-based, always available)
        │
        ▼
    String (human-readable description)
```

---

## MLX Description Generator

### Model Selection

See `020-local-llm-evaluation.md` for full LLM evaluation. Summary:

| Model | Size (4-bit) | iPhone 15 Pro | M2 MacBook | Quality |
|---|---|---|---|---|
| Phi-3 Mini | 2.2 GB | ✅ Fast | ✅ Very fast | Good |
| Qwen3 4B | 2.5 GB | ✅ Moderate | ✅ Fast | Very Good |
| Qwen3 8B | 4.8 GB | ❌ Too large | ✅ Fast | Excellent |

**Mac:** Qwen3 8B (4-bit) — best quality  
**iPhone:** Phi-3 Mini or Qwen3 4B (4-bit) — balance of quality and memory

### Prompt Template

```python
DESCRIPTION_SYSTEM_PROMPT = """You are a financial assistant. Generate a single, 
concise, human-readable description of a bank transaction. 
Rules:
- One sentence only. Maximum 20 words.
- Include the amount with ₹ symbol.
- Do NOT invent information not in the input.
- Do NOT include the date (it is shown separately in the UI).
- Use natural language, not telegraphic style.
- If it is a credit, say "received" or "credited". If debit, say "paid" or "sent".
"""

def build_description_prompt(input: DescriptionInput) -> str:
    parts = [
        f"Narration: {input.narration}",
        f"Amount: ₹{input.amount}",
        f"Direction: {'credit (money received)' if input.direction == 'credit' else 'debit (money sent)'}",
    ]
    if input.merchantName:
        parts.append(f"Merchant: {input.merchantName}")
    if input.category:
        parts.append(f"Category: {input.category.rawValue}")
    if input.intent:
        parts.append(f"Intent: {input.intent.rawValue}")
    if input.paymentChannel:
        parts.append(f"Channel: {input.paymentChannel.rawValue}")
    
    return DESCRIPTION_SYSTEM_PROMPT + "\n\n" + "\n".join(parts) + "\n\nDescription:"
```

### Output Constraints

```python
LLM_OPTIONS = LLMOptions(
    maxNewTokens=50,       # hard cap: 50 tokens ≈ 35 words
    temperature=0.3,       # low temperature: factual, not creative
    stopSequences=["\n"],  # stop at newline (one sentence)
    repetitionPenalty=1.2,
)
```

### Factuality Guard

Post-generation, verify the amount in the output matches the input:

```swift
func validateDescription(_ description: String, amount: Decimal) -> Bool {
    let amountString = "₹\(amount)"
    let amountStringAlt = "₹ \(amount)"
    // Check amount appears correctly
    return description.contains(amountString) || description.contains(amountStringAlt)
}

// If validation fails: fall back to FallbackGenerator
```

---

## FallbackGenerator (Retained)

Template-based generator, always available as final fallback:

```swift
// DescriptionGeneration/FallbackGenerator.swift

func generate(_ input: DescriptionInput) -> String {
    switch (input.direction, input.intent) {
    case (.credit, .receiveSalary):
        return "Salary credit of ₹\(input.amount) received."
    case (.credit, .receiveRefund):
        return "Refund of ₹\(input.amount) from \(input.merchantName ?? "merchant")."
    case (.debit, .payRent):
        return "Rent payment of ₹\(input.amount)."
    case (.debit, .payDebt):
        return "Credit card payment of ₹\(input.amount)."
    case (.debit, .investSIP):
        return "Investment of ₹\(input.amount) to \(input.merchantName ?? "fund")."
    default:
        let direction = input.direction == .credit ? "received" : "paid"
        let merchant = input.merchantName.map { " to/from \($0)" } ?? ""
        return "₹\(input.amount) \(direction)\(merchant)."
    }
}
```

Fallback output is factually correct (grounded in input fields) even if not natural.

---

## Batching Strategy

Description generation is expensive (LLM inference). Run in batches, not per-transaction:

```swift
// Deferred async stage — not on critical import path
actor DescriptionGenerationQueue {
    private var pending: [DescriptionInput] = []
    private let batchSize = 20
    private let idleDelaySeconds: Double = 30
    
    func enqueue(_ input: DescriptionInput) {
        pending.append(input)
        if pending.count >= batchSize {
            Task { await processBatch() }
        }
    }
    
    private func processBatch() async {
        let batch = Array(pending.prefix(batchSize))
        pending.removeFirst(min(batchSize, pending.count))
        
        // Process only if device is not under thermal pressure
        guard ProcessInfo.processInfo.thermalState < .serious else { return }
        
        for input in batch {
            let description = await descriptionGenerator.generate(input)
            await persistDescription(input.transactionID, description)
        }
    }
}
```

---

## Fine-Tuning Strategy

For maximum quality on Indian financial narrations, fine-tune the base LLM on a domain-specific dataset:

```jsonl
// transaction_description_training.jsonl
{"input": {"narration": "UPI-ZEPTO MARKETPLACE PR", "amount": 349, "direction": "debit", "merchant": "Zepto", "category": "groceries"}, "output": "Quick grocery order from Zepto for ₹349."}
{"input": {"narration": "SALARY CREDIT NEFT", "amount": 85000, "direction": "credit", "merchant": "Acme Corp", "category": "salary"}, "output": "Monthly salary of ₹85,000 credited from Acme Corp."}
{"input": {"narration": "LIC PREMIUM NACH", "amount": 2500, "direction": "debit", "category": "insurance"}, "output": "LIC insurance premium of ₹2,500 auto-debited."}
```

Fine-tuning approach: LoRA (Low-Rank Adaptation) on the base Phi-3 Mini or Qwen3 4B model.

Training: `training/description/train.py` — supervised fine-tuning on 10,000 (input, output) pairs.

---

## Performance Targets

| Metric | Target |
|---|---|
| BERTScore F1 (vs. human reference) | ≥ 0.85 |
| Factuality (amount correct) | ≥ 0.99 |
| Hallucination rate | ≤ 0.02 |
| Human eval mean (1–5 scale) | ≥ 3.5 |
| LLM generation P95 latency (iPhone 15 Pro) | < 2,000 ms |
| FallbackGenerator latency | < 1 ms |

---

## Testing Strategy

- **Unit tests:** FallbackGenerator tested with all intent × direction combinations
- **Integration tests:** MLX generator tested with golden (input, output) pairs; BERTScore verified programmatically
- **Factuality tests:** Automated check that amount appears correctly in output for all test cases
- **CI:** FallbackGenerator runs in CI; MLX generator tested only on ML hardware (skipped in simulator)

---

## Risks

| Risk | Mitigation |
|---|---|
| LLM mentions wrong amount (hallucination) | Factuality guard post-generation; fall back to FallbackGenerator on failure |
| LLM generates > 1 sentence (ignores constraint) | `stopSequences=["\n"]` + truncate to first sentence in Swift |
| MLX LLM unavailable on older devices (< 6 GB RAM) | Fallback chain always ends at FallbackGenerator; no crash possible |
| Fine-tuning LoRA degrades general instruction following | Evaluate on diverse held-out prompts after fine-tuning; compare base vs. fine-tuned |
| Apple Intelligence API changes between iOS versions | `AppleIntelligenceAdapter` versioned separately; availability check at runtime |
