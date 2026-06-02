---
doc: 020-local-llm-evaluation
version: 0.1.0
status: Draft
date: 2026-06-02
---

# 020 — Local LLM Evaluation

## Purpose

This document defines the evaluation framework and candidate shortlist for selecting the on-device local LLM used in FinanceOS financial intelligence features. The selected model must run entirely on-device on both Mac (Apple Silicon) and iPhone (A16/A17), produce coherent financial insights and descriptions in English, handle Indian financial terminology accurately, and emit reliable structured JSON output.

No candidate that requires cloud inference is eligible regardless of quality score.

---

## Architecture

```
Evaluation Harness (Python, runs offline on Mac)
    │
    ├── test_prompts/
    │   ├── description_prompts.jsonl   (200 prompts)
    │   ├── insight_prompts.jsonl       (100 prompts)
    │   ├── tool_call_prompts.jsonl     (50 prompts)
    │   └── indian_finance_prompts.jsonl (50 prompts)
    │
    ├── ModelRunner
    │   ├── MLXRunner      → mlx_lm.generate()
    │   └── CoreMLRunner   → swift eval harness via XCTest
    │
    ├── Scorer
    │   ├── RougeScorer    (ROUGE-L vs reference)
    │   ├── JSONValidator  (schema compliance)
    │   ├── FactChecker    (figures match input context)
    │   └── HumanReview    (sampled 50/400 outputs)
    │
    └── ResultsDB          → results/eval_<date>.jsonl
```

---

## Candidate Models

### Mac — Apple Silicon (M-series)

| # | Model | Quantization | Approx Size | MLX Repo |
|---|---|---|---|---|
| M1 | Qwen3 4B | 4-bit (Q4_K_M) | ~2.5 GB | mlx-community/Qwen3-4B-4bit |
| M2 | Qwen3 8B | 4-bit (Q4_K_M) | ~5.0 GB | mlx-community/Qwen3-8B-4bit |
| M3 | Phi-4 Mini | 4-bit (Q4_K_M) | ~2.2 GB | mlx-community/phi-4-mini-instruct-4bit |
| M4 | Llama 3.2 3B | 4-bit (Q4_K_M) | ~2.0 GB | mlx-community/Llama-3.2-3B-Instruct-4bit |
| M5 | Gemma 3 4B | 4-bit (Q4_K_M) | ~2.5 GB | mlx-community/gemma-3-4b-it-4bit |

### iPhone — A16/A17 Pro

| # | Model | Quantization | Approx Size | Source |
|---|---|---|---|---|
| I1 | Qwen3 1.7B | CoreML 4-bit | ~1.0 GB | Convert from HF |
| I2 | Phi-4 Mini | CoreML 4-bit | ~2.0 GB | Convert from HF |
| I3 | Llama 3.2 1B | CoreML 4-bit | ~0.7 GB | apple/coremltools |
| I4 | Gemma 3 1B | CoreML 4-bit | ~0.7 GB | Convert from HF |

---

## Inputs

| Input | Details |
|---|---|
| 400-prompt evaluation set | Described in Test Prompt Set section |
| Reference outputs | Human-written for description task (200); structured ground truth for insight task (100) |
| Device specs | Mac M2 16GB, Mac M1 8GB (RAM-constrained), iPhone 15 Pro (A17), iPhone 14 (A16) |
| Scoring rubric | Defined in Scoring Rubric section |

---

## Outputs

| Output | Format |
|---|---|
| Per-model score card | JSON: model_id, dimension scores, aggregate score, recommendation_tier |
| Latency measurements | JSONL: model_id, prompt_id, ttft_ms, tokens_per_sec, peak_rss_mb |
| Human review samples | CSV: prompt, output, reviewer_score (1–5), notes |
| Final recommendation | Section in this document; also written to `model_registry.yaml` |

---

## Interfaces

### EvaluationHarness (Python)

```python
class ModelEvaluator:
    def __init__(self, model_id: str, runner: ModelRunner): ...

    def evaluate_all(
        self,
        prompt_sets: list[PromptSet]
    ) -> EvalReport: ...

    def measure_latency(
        self,
        prompt: str,
        n_tokens: int = 200
    ) -> LatencyMeasurement: ...
```

### Swift Evaluation Harness (XCTest)

```swift
/// Used for CoreML model evaluation on device.
protocol CoreMLEvaluationRunner {
    func run(prompt: String, maxTokens: Int) async throws -> EvalOutput
    func measureMemory(during block: () async throws -> Void) async throws -> MemoryMeasurement
}

struct EvalOutput {
    let text: String
    let firstTokenLatencyMs: Double
    let tokensPerSecond: Double
}

struct MemoryMeasurement {
    let baselineMB: Double
    let peakMB: Double
    let modelLoadMB: Double
}
```

---

## Benchmark Dimensions

### 1. Memory

- **Model load RSS**: RSS increase from before `model.load()` to after, steady state
- **Peak inference RSS**: maximum RSS during a 200-token generation
- Measured with `task_info(TASK_VM_INFO)` on Mac; `os_proc_available_memory()` proxy on iPhone
- Threshold: model load must leave >= 1 GB free RAM on target device

### 2. Cold Start (First Token Latency)

- Time from `generate()` call to first token emitted
- Measured: 5 runs, report median (ms)
- Mac target: < 2000ms; iPhone target: < 4000ms

### 3. Throughput (Tokens/sec)

- 200-token generation, prompt length ~300 tokens (typical insight prompt)
- Measured: 5 runs, report median
- Mac target: >= 20 tok/s; iPhone target: >= 8 tok/s

### 4. Description Generation Quality (ROUGE-L)

- 200 transaction narration → description prompts
- Reference: human-written descriptions
- Score: ROUGE-L recall against reference set
- Target: >= 0.45 ROUGE-L

### 5. Insight Generation Quality

- 100 structured context JSON → insight prompts
- Scored on: relevance (0–2), factual accuracy (0–2), fluency (0–1) — max 5 per insight
- Relevance: does the insight address the requested type?
- Factual accuracy: do figures in body text match `supporting_data` and input context?
- Fluency: is the text grammatically correct and natural?
- Target: >= 3.5 / 5.0 average

### 6. Structured JSON Output Reliability

- 50 prompts explicitly requesting JSON output per schema
- Score: % of outputs that parse without repair
- Strict: valid JSON, correct top-level keys, correct value types
- Lenient: valid JSON after stripping markdown fences
- Target: >= 90% lenient parse rate

### 7. Indian Financial Terminology Accuracy

- 50 prompts covering UPI, NACH, IMPS, NEFT, RTGS, VPA, IFSC, common Indian merchant names, regional bank names
- Scored: correct identification/usage (0 or 1 per term)
- Terms tested: UPI payment detection, NACH debit classification, Paytm/PhonePe/GPay routing, BESCOM/BWSSB utility classification, Zomato/Swiggy food classification
- Target: >= 85% accuracy

### 8. Reasoning Quality

- 20 multi-step financial analysis prompts (e.g., "Given this cashflow, in how many months does savings reach ₹100,000?")
- Scored: correct final answer (1), correct reasoning steps (0–2), clear explanation (0–1) — max 4
- Target: >= 2.5 / 4.0 average

---

## Test Prompt Set (400 Prompts)

### Description Generation (200 prompts)

Narration patterns covered:

```
UPI/P2P:
  "UPI/CR/2601234567/PAYTM/MERCHANT@PAYTM/Coffee shop"
  "UPI-Cr-PHONEPE-9876543210@ybl-Transfer"

NEFT/RTGS:
  "NEFT/RTGSHDFC0001234-AMAZON SELLER SERVICES"
  "RTGS-BENEFICIARY NAME-UTR123456"

NACH/ECS:
  "NACH/DEBIT/HDFC0001234/LIC PREMIUM"
  "ECS DEBIT - LOAN EMI REF 12345"

ATM/POS:
  "ATM WDL 12345 SBI BRANCH NAME"
  "POS/VISA/SWIGGY INTERNET/INR 449"

Salary/Income:
  "SALARY CREDIT - EMPLOYER NAME - APR 2026"
  "NEFT CR-COMPANY NAME-SALARY"

Utility:
  "BILLPAY/ELECTRICITY/BESCOM/ACNO 12345"
  "NACH/AIRTEL BROADBAND/MONTHLY"
```

Each prompt: system + "Generate a 1-sentence plain-English description of this transaction narration: {narration}. Respond with only the description."

### Insight Generation (100 prompts)

- 20 prompts per insight type (monthly_summary, spending_analysis, recurring_commitments, category_trends, cash_flow_analysis — 5 types; unusual_activity_summary and savings_opportunity get 10 each)
- Each prompt includes a realistic `InsightContext` JSON (see 019-insight-generation.md)
- 30 prompts use batch format (all 7 types in one call)

### Tool Call Format (50 prompts)

- OpenAI-compatible function calling format
- Tests: correct tool name selection, correct parameter extraction, JSON validity
- Tools: QueryTransactions, QueryBudgets, QueryMerchants (see 023-agent-architecture.md)

### Indian Finance Terminology (50 prompts)

- 10 prompts: classify transaction channel (UPI/NEFT/RTGS/NACH/ATM/POS)
- 10 prompts: identify merchant category from narration
- 10 prompts: detect income vs expense from narration patterns
- 10 prompts: resolve VPA to merchant name (e.g., `zomato@icici` → Zomato)
- 10 prompts: classify Indian utility providers from narration

---

## Scoring Rubric

### Aggregate Score Formula

```
aggregate = (
    0.15 * (rouge_l_score / 0.5)           +  # description quality (normalized to 0.5 target)
    0.20 * (insight_score / 5.0)            +  # insight quality
    0.20 * (json_reliability_strict / 1.0)  +  # JSON reliability
    0.20 * (indian_terms_accuracy / 1.0)    +  # Indian finance accuracy
    0.10 * (reasoning_score / 4.0)          +  # reasoning
    0.15 * latency_score                       # latency (see below)
)

latency_score:
    Mac:     tok/s >= 40 → 1.0; >= 25 → 0.8; >= 15 → 0.5; < 15 → 0.2
    iPhone:  tok/s >= 15 → 1.0; >= 10 → 0.8; >= 6  → 0.5; < 6  → 0.2
```

All dimension scores clamp to [0.0, 1.0]. Aggregate score range: [0.0, 1.0].

### Human Review Scoring (sampled 50 outputs per model)

Reviewers score on 5-point Likert scale:
1. Response is incorrect or harmful
2. Response is off-topic or incoherent
3. Response is correct but awkward
4. Response is correct and natural
5. Response is correct, natural, and notably useful

---

## Recommendation Matrix

### Mac Primary Recommendation

**Qwen3 8B (M2)** — _recommended if device has >= 8 GB RAM_

Justification:
- 8B parameter scale provides significantly better instruction following and JSON reliability than 4B models
- Qwen3 lineage has strong multilingual and structured output performance
- 4-bit quantization at ~5 GB leaves comfortable headroom on 16 GB devices
- MLX community maintains active quantized releases with ANE optimization

Expected scores: ROUGE-L ~0.52, JSON reliability ~95%, Indian terms ~88%, throughput ~28 tok/s on M2.

### Mac Fallback (RAM-Constrained, < 8 GB)

**Phi-4 Mini (M3)** — _recommended for 8 GB devices_

Justification:
- ~2.2 GB leaves adequate headroom on 8 GB devices
- Phi-4 Mini punches above its weight on instruction following due to synthetic data training
- Strong structured output reliability relative to parameter count
- Lower throughput than Qwen3 4B but more consistent JSON formatting

### iPhone Primary Recommendation

**Phi-4 Mini CoreML (I2)** — _recommended for A17 Pro (iPhone 15 Pro+)_

Justification:
- ~2 GB fits within A17 Pro Neural Engine budget without thermal pressure
- Best instruction-following at this size class
- CoreML conversion well-supported via coremltools >= 7.1

### iPhone Fallback

**Rule-based FallbackGenerator** (existing `FinanceIntelligence/Description/FallbackGenerator`)

Used when:
- Device is iPhone 14 or earlier (A15 or below, < 6 GB RAM)
- User has disabled on-device ML in settings
- Model download has not completed
- `ModelManager` reports insufficient free space

The fallback is always available, deterministic, and produces acceptable (if less natural) output.

---

## Evaluation Methodology

### Environment Standardization

- All Mac benchmarks on same machine (M2 16 GB, macOS 15)
- All iPhone benchmarks on same device (iPhone 15 Pro, iOS 18)
- No other heavy applications running during benchmark
- 3-run warmup before measurement window

### Reproducibility

- All prompts stored in `scripts/eval/test_prompts/` as JSONL, versioned in git
- Random seed fixed for any sampling
- Results committed to `scripts/eval/results/` as JSONL

### Human Review Protocol

- 50 outputs sampled uniformly per model (not cherry-picked)
- Two independent reviewers score each sample
- Disagreements > 1 point resolved by third reviewer
- Reviewer instructions stored in `scripts/eval/REVIEWER_GUIDE.md`

---

## Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Qwen3 8B causes memory pressure on 16 GB Mac | High | Monitor peak RSS; fall back to Qwen3 4B if peak > 12 GB |
| CoreML conversion degrades model quality | Medium | Validate conversion: Python inference vs CoreML inference on 100 prompts, assert ROUGE-L delta < 0.05 |
| JSON output reliability degrades on iPhone CoreML vs MLX Mac | Medium | Measure separately; apply stricter prompt constraints if needed |
| Model weights licensing incompatible with App Store | High | Verify licenses before selection: Qwen3 (Apache 2.0), Phi-4 (MIT), Llama 3.2 (Meta Llama 3.2 license — commercial use allowed), Gemma 3 (Gemma Terms — review required) |
| Evaluation set not representative of production narrations | Medium | Seed 30% of prompts from real anonymized transaction narrations (stripped of PII) |

---

## Benchmarks (Expected Targets by Model)

| Model | Platform | Tok/s | Cold Start | Peak RSS | ROUGE-L | JSON % | Aggregate |
|---|---|---|---|---|---|---|---|
| Qwen3 8B | Mac M2 | 28 | 1800ms | 6.2 GB | 0.52 | 94% | 0.82 |
| Qwen3 4B | Mac M2 | 45 | 1200ms | 3.1 GB | 0.47 | 91% | 0.76 |
| Phi-4 Mini | Mac M2 | 42 | 1100ms | 2.7 GB | 0.44 | 93% | 0.74 |
| Llama 3.2 3B | Mac M2 | 50 | 900ms | 2.5 GB | 0.40 | 87% | 0.68 |
| Gemma 3 4B | Mac M2 | 38 | 1300ms | 3.0 GB | 0.43 | 89% | 0.71 |
| Phi-4 Mini | iPhone A17 | 11 | 3200ms | 2.1 GB | 0.42 | 90% | 0.72 |
| Qwen3 1.7B | iPhone A17 | 14 | 2800ms | 1.1 GB | 0.37 | 85% | 0.64 |
| Llama 3.2 1B | iPhone A17 | 18 | 2200ms | 0.8 GB | 0.33 | 82% | 0.58 |
| Gemma 3 1B | iPhone A17 | 17 | 2400ms | 0.8 GB | 0.34 | 83% | 0.59 |

_These are pre-evaluation estimates. Actual results from harness override these values._

---

## Testing Strategy

### Harness Validation

- Unit test `RougeScorer` against known ROUGE-L reference pairs
- Unit test `JSONValidator` against 10 valid and 10 invalid schema samples
- Integration test: run all 400 prompts against a small stub model; assert no harness errors

### Continuous Evaluation

- Re-run eval harness on model version bumps (triggered by `model_registry.yaml` change)
- Gate model promotion: aggregate score must not regress > 0.03 from prior version
- Weekly scheduled run on main benchmark device; results diff posted to PR

### Evaluation Result Archiving

- Each run produces `results/eval_<YYYY-MM-DD>_<model_id>.jsonl`
- Summary CSV committed to `scripts/eval/results/summary.csv`
- Human review sheets stored in `scripts/eval/results/human_review/`
