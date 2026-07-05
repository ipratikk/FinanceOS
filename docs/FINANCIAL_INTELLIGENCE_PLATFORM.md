# FINANCEOS FINANCIAL INTELLIGENCE PLATFORM - MASTER EXECUTION PROMPT

You are acting as the Principal ML Architect, Principal iOS Architect, Principal Data Scientist, and Technical Program Manager for FinanceOS.

Your job is to completely audit, redesign, document, implement, train, benchmark, and integrate a world-class offline-first Financial Intelligence Platform.

This is NOT a finance app feature.

This is a standalone platform that will power all financial intelligence capabilities across FinanceOS.

The final result should resemble the intelligence quality of:

* Copilot Money
* Monarch
* Ramp
* Brex
* Mercury
* ChatGPT
* Claude
* Gemini

while remaining:

* Offline-first
* Privacy-first
* Local-first
* Apple ecosystem focused
* Compatible with macOS and iOS
* Swift Package based
* MLX compatible
* CoreML compatible

The system must never depend on OpenAI APIs, Claude APIs, Gemini APIs, or any cloud inference service.

Cloud services may be used ONLY for research, benchmarking, dataset generation, and evaluation during development.

All production inference must run locally.

---

# EXISTING PROJECT CONTEXT

Current project:

FinanceOS

Technology:

* SwiftUI
* GRDB
* SQLite
* Swift Package architecture
* macOS
* iOS

Existing packages include:

* FinanceCore
* FinanceDatabase
* FinanceParsers

Architecture requirements:

* UI must remain completely decoupled
* No business logic in views
* No database access in views
* No ML logic in views
* Protocol-driven architecture
* Dependency injection
* Testability first
* Modular package architecture

---

# PRIMARY OBJECTIVE

Create a brand-new package:

FinanceIntelligence

This package becomes the single source of truth for all intelligence operations.

The package must own:

* merchant recognition
* merchant normalization
* category classification
* intent classification
* recurring transaction detection
* salary detection
* subscription detection
* anomaly detection
* transaction linking
* transaction embeddings
* merchant embeddings
* transaction clustering
* financial insight generation
* transaction description generation
* financial chat assistant
* financial agent system
* local LLM integration

No hardcoded rule engine.

No giant switch statements.

No narration.contains() implementations.

No merchant lookup dictionaries except where absolutely required for data generation.

All intelligence should be model-driven.

---

# PHASE 1

FULL AUDIT

Before implementation begins:

Create:

docs/financial-intelligence/

Required documents:

000-overview.md

001-current-state-audit.md

002-gap-analysis.md

003-target-architecture.md

004-data-models.md

005-inference-pipeline.md

006-package-architecture.md

007-model-registry.md

008-benchmark-plan.md

009-evaluation-metrics.md

010-training-data-pipeline.md

011-dataset-schema.md

012-merchant-normalization.md

013-category-classification.md

014-intent-classification.md

015-recurring-detection.md

016-link-prediction.md

017-anomaly-detection.md

018-description-generation.md

019-insight-generation.md

020-local-llm-evaluation.md

021-mlx-integration.md

022-coreml-export-pipeline.md

023-agent-architecture.md

024-roadmap.md

Every document must contain:

* purpose
* architecture
* diagrams
* inputs
* outputs
* interfaces
* implementation plan
* risks
* benchmarks
* testing strategy

---

# PHASE 2

AUDIT EXISTING CODE

Perform a full repository audit.

Analyze:

* parsers
* categorization
* merchant detection
* description generation
* reporting
* analytics

Identify:

* duplicated logic
* hidden rule engines
* regex dependencies
* hardcoded mappings
* poor abstractions
* scalability bottlenecks

Produce:

001-current-state-audit.md

and

002-gap-analysis.md

with actionable findings.

---

# PHASE 3

DESIGN THE INTELLIGENCE PLATFORM

Create new package:

Packages/
└── FinanceIntelligence

Structure:

FinanceIntelligence/

Sources/

FinanceIntelligence/

MerchantRecognition/

Categorization/

IntentDetection/

RecurringDetection/

SubscriptionDetection/

IncomeDetection/

Embeddings/

LinkPrediction/

Clustering/

AnomalyDetection/

DescriptionGeneration/

InsightGeneration/

Agent/

LocalLLM/

Inference/

Evaluation/

Models/

Protocols/

Infrastructure/

Testing/

Examples/

Every module must be independently testable.

---

# PHASE 4

BUILD DATASET GENERATION SYSTEM

Create:

training/

datasets/

scripts/

docs/

Build a complete synthetic data generation pipeline.

The system must generate millions of realistic Indian financial transactions.

Support:

Banks:

* HDFC
* ICICI
* SBI
* Axis
* Kotak
* Yes Bank
* Federal
* IDFC
* IndusInd
* AU
* HSBC
* Standard Chartered

Cards:

* Amex
* HDFC
* ICICI
* Axis
* SBI
* Scapia
* OneCard
* Amazon Pay
* Flipkart Axis

UPI:

* GPay
* PhonePe
* Paytm
* BHIM
* Cred
* Amazon Pay

Payment Channels:

* UPI
* IMPS
* NEFT
* RTGS
* Card
* ACH
* NACH
* ECS
* AutoPay

Merchants:

Generate tens of thousands of merchant variants.

Examples:

Zepto

must generate:

* ZEPTO
* ZEPTO MARKETPLACE
* ZEPTO MARKETPLACE PR
* ZEPTONOW
* ZEPTOMARKETPLACE
* ZEPTO.RZP
* etc

Do this for every merchant.

---

# REQUIRED DATASETS

merchant_training.csv

category_training.csv

intent_training.csv

recurring_training.csv

subscription_training.csv

income_training.csv

link_prediction_training.csv

anomaly_training.csv

transaction_description_training.jsonl

insight_generation_training.jsonl

embedding_training.jsonl

---

# PHASE 5

TRAINING PIPELINE

Create:

training/

merchant/

category/

intent/

recurring/

subscription/

income/

embedding/

link_prediction/

anomaly/

description/

insight/

Each model must have:

train.py

evaluate.py

export_coreml.py

benchmark.py

README.md

---

# MODEL REQUIREMENTS

MODEL 1

Merchant Recognition

Input:

raw narration

Output:

canonical merchant

---

MODEL 2

Category Classification

Output:

Food
Groceries
Rent
Salary
Insurance
Travel
Utilities
Shopping
Entertainment
Investments
Transfers
Credit Card Payments
Loans

and more.

---

MODEL 3

Intent Classification

Examples:

salary

rent

subscription

refund

investment

insurance

credit_card_payment

loan_payment

peer_transfer

grocery

food

fuel

travel

education

healthcare

etc

---

MODEL 4

Recurring Detection

monthly

weekly

yearly

quarterly

irregular

---

MODEL 5

Subscription Detection

true/false

confidence

---

MODEL 6

Income Detection

salary

bonus

refund

reimbursement

interest

cashback

other_income

---

MODEL 7

Embedding Model

Generate dense vectors.

Used for:

* merchant similarity
* transaction similarity
* clustering
* linking

---

MODEL 8

Link Prediction

Predict money-flow relationships.

Examples:

Salary
→ Rent

Salary
→ Credit Card

Salary
→ SIP

Salary
→ Insurance

---

MODEL 9

Anomaly Detection

Detect:

* unusual spending
* merchant spikes
* duplicate transactions
* abnormal recurring changes

---

MODEL 10

Description Generator

Input:

raw transaction

Output:

human-readable financial description

Example:

UPI-CRED CLUB

↓

Credit card bill payment made via CRED.

---

MODEL 11

Insight Generator

Generate:

* monthly summaries
* spending analysis
* recurring commitments
* category trends
* cash-flow analysis

---

# PHASE 6

LOCAL LLM RESEARCH

Create:

020-local-llm-evaluation.md

Evaluate:

Qwen3 4B

Qwen3 8B

Phi-4 Mini

Llama 3.2

Gemma

Mistral

Benchmark:

* memory
* speed
* quality
* reasoning
* structured extraction
* iPhone performance
* Mac performance

---

# REQUIRED DECISION

Recommend:

Mac:

best model

iPhone:

best model

Provide evidence.

---

# PHASE 7

MLX INTEGRATION

Preferred runtime:

MLX

Create:

FinanceIntelligence/LocalLLM

Build:

LLMProvider

MLXProvider

PromptBuilder

ToolCallingEngine

StreamingInference

ContextManager

ConversationMemory

ModelManager

QuantizationManager

---

# PHASE 8

AGENT ARCHITECTURE

Build:

FinanceAgent

Tools:

QueryTransactionsTool

QueryBudgetsTool

QueryAccountsTool

QueryInvestmentsTool

QueryCategoriesTool

QueryMerchantsTool

QueryRecurringTool

The LLM must never directly access the database.

All access must happen through tools.

---

# PHASE 9

EVALUATION FRAMEWORK

Create evaluation suite.

Metrics:

Merchant Accuracy

Category Accuracy

Intent Accuracy

Recurring Accuracy

Subscription Accuracy

Income Accuracy

Description Quality

Insight Quality

Latency

Memory Usage

Battery Impact

Model Size

Cold Start

Warm Start

---

# PHASE 10

COREML EXPORT

Every production model must support:

CoreML export

Required outputs:

merchant.mlmodel

category.mlmodel

intent.mlmodel

recurring.mlmodel

subscription.mlmodel

income.mlmodel

embedding.mlmodel

link_prediction.mlmodel

anomaly.mlmodel

---

# PHASE 11

INTEGRATION

Expose protocols only.

No UI dependencies.

No SwiftUI dependencies.

No GRDB dependencies in intelligence modules.

Use clean interfaces.

Example:

MerchantRecognizer

CategoryClassifier

IntentClassifier

RecurringDetector

EmbeddingGenerator

DescriptionGenerator

InsightGenerator

LLMProvider

AgentProvider

---

# DELIVERABLES

Produce:

1. Full audit
2. Full documentation
3. Dataset generation system
4. Synthetic dataset generator
5. Training pipelines
6. Evaluation pipelines
7. Benchmark framework
8. CoreML export pipeline
9. MLX integration
10. Local LLM integration
11. FinanceAgent
12. Swift package implementation
13. Tests
14. Example applications
15. Migration plan from existing implementation

---

# EXECUTION RULES

Before coding:

1. Audit first.
2. Document first.
3. Design first.

Never jump directly into implementation.

Every major milestone must include:

* documentation updates
* architecture review
* benchmark results
* migration strategy

Prefer maintainability over speed.

Prefer reproducibility over shortcuts.

Prefer model-driven intelligence over rule engines.

Think like a team building the financial intelligence layer for the next decade of FinanceOS.

# APPENDIX A — NON-NEGOTIABLE IMPLEMENTATION CONSTRAINTS

## CRITICAL SUCCESS CRITERIA

The goal of this project is NOT:

* Swift categorization code
* Regex-based intelligence
* Merchant mapping dictionaries
* String matching systems
* Template description generators

The goal is:

A reproducible machine learning platform capable of generating, training, evaluating, exporting, versioning, updating, and deploying financial intelligence models.

The primary deliverable is the ML platform.

The Swift package is a consumer of trained models.

---

# FORBIDDEN PRODUCTION IMPLEMENTATIONS

The following are prohibited inside production inference code:

```swift
if narration.contains(...)
```

```swift
switch merchant
```

```swift
merchantAliases
```

```swift
merchantMappings
```

```swift
merchantRegexes
```

```swift
hardcodedCategoryMappings
```

```swift
hardcodedIntentMappings
```

```swift
generatedDescriptionTemplates
```

```swift
stringInterpolationDescriptionGenerators
```

Exceptions:

* dataset generation
* evaluation tooling
* debugging utilities
* migration tooling

These constructs must never be used as the primary production inference mechanism.

If a capability requires rules to function, the model architecture is considered incorrect and must be redesigned.

---

# SWIFT RESPONSIBILITY

Swift must only perform:

* model loading
* inference execution
* confidence scoring
* caching
* orchestration
* personalization overlays
* tool execution

Swift must never perform intelligence classification.

---

# PYTHON OWNERSHIP REQUIREMENT

All production models must originate from Python training pipelines.

No model may be manually created in:

* Xcode
* CreateML GUI
* CreateML App
* CoreML Model Editor

The repository must support complete reproducibility.

Every model must contain:

training/<model_name>/

train.py

evaluate.py

benchmark.py

export_coreml.py

README.md

requirements.txt

The model must be reproducible from source.

---

# COREMLTOOLS REQUIREMENT

All CoreML exports must be generated through:

coremltools

The repository must never rely on:

* manually generated mlmodels
* CreateML exports
* GUI-generated models

The source of truth is always:

Python training code.

CoreML artifacts are generated outputs.

---

# MODEL REGISTRY

Create:

training/model_registry.yaml

Every model entry must contain:

name

version

dataset_version

training_date

evaluation_date

accuracy

f1_score

artifact_hash

coreml_hash

training_commit

dataset_commit

Inference systems must load models via registry.

Model filenames must never be hardcoded.

---

# DATASET-FIRST DEVELOPMENT

The primary deliverable is the dataset generation system.

Claude must prioritize:

scripts/generate_merchants.py

scripts/generate_transactions.py

scripts/generate_categories.py

scripts/generate_salary_patterns.py

scripts/generate_recurring_patterns.py

scripts/generate_subscription_patterns.py

scripts/generate_intent_patterns.py

scripts/generate_linking_examples.py

scripts/generate_anomaly_examples.py

over Swift inference code.

Models are outputs of datasets.

Datasets are not outputs of models.

---

# MERCHANT MODEL REQUIREMENTS

Input:

Raw transaction narration

Output:

Canonical merchant

Required architecture:

Sentence Embeddings
+
Classifier

Examples:

UPI-ZEPTO

UPI-ZEPTO MARKETPLACE

UPI-ZEPTO MARKETPLACE PR

ZEPTO.RZP

must resolve through model inference.

Merchant dictionaries are prohibited.

Target metrics:

Top-1 Accuracy > 95%

Top-3 Accuracy > 99%

Unknown Merchant Detection > 90%

---

# CATEGORY MODEL REQUIREMENTS

Required output:

category

subcategory

confidence

Target:

Macro F1 > 92%

---

# INTENT MODEL REQUIREMENTS

Target:

Macro F1 > 95%

Must support:

salary

rent

credit_card_payment

investment

insurance

loan_payment

peer_transfer

subscription

refund

cashback

income

grocery

food

fuel

travel

utilities

education

healthcare

and additional classes.

---

# DESCRIPTION GENERATION REQUIREMENTS

Transaction descriptions must be generated through local LLM inference.

Prohibited:

* templates
* string interpolation
* switch statements
* rule-based text generation

Required:

Local LLM

Examples:

Qwen3 4B

Qwen3 8B

Phi-4 Mini

through MLX.

Description generation is an LLM problem.

Not a Swift problem.

---

# INSIGHT GENERATION REQUIREMENTS

Monthly insights must be generated through local LLM inference.

Prohibited:

Hardcoded summary generation.

Required:

Structured financial data
+
Prompting
+
Local LLM
+
Tool execution

---

# SELF-LEARNING SYSTEM REQUIREMENT

FinanceOS must continuously improve based on user behavior.

Static intelligence is considered a failure.

The platform must support:

* feedback collection
* personalization
* online learning
* incremental retraining
* model promotion
* rollback

---

# USER FEEDBACK DATASETS

Create:

datasets/feedback/

merchant_feedback.jsonl

category_feedback.jsonl

intent_feedback.jsonl

recurring_feedback.jsonl

description_feedback.jsonl

link_prediction_feedback.jsonl

subscription_feedback.jsonl

income_feedback.jsonl

Every user correction becomes training data.

---

# PERSONALIZATION LAYER

Required architecture:

Global Models

*

User Personalization Layer

*

Feedback Layer

=

Final Prediction

The system must become more accurate for a user over time.

---

# USER KNOWLEDGE GRAPH

Create:

FinanceIntelligence/Personalization/

Components:

FeedbackStore

UserKnowledgeGraph

PersonalMerchantStore

PersonalCategoryStore

PersonalIntentStore

PersonalEmbeddingStore

PersonalDescriptionStore

This is not a rule engine.

This is user-owned learned knowledge.

---

# INCREMENTAL RETRAINING

Create:

training/retraining/

merge_feedback.py

build_incremental_dataset.py

train_incremental.py

evaluate_incremental.py

promote_model.py

Support:

Base Dataset

*

Feedback Dataset

↓

Candidate Model

↓

Evaluation

↓

Promotion

↓

Deployment

---

# MODEL VERSIONING

Every model must support:

versioning

promotion

rollback

shadow evaluation

A newly trained model must never replace the active model without evaluation.

---

# FUTURE PERSONAL FINE-TUNING

Architecture must support:

Base Foundation Model

*

FinanceOS Domain LoRA

*

User Personal LoRA

For future local fine-tuning workflows.

---

# FINAL ACCEPTANCE CRITERIA

The project is considered complete only if:

1. Training pipelines exist.
2. Dataset generation pipelines exist.
3. Evaluation pipelines exist.
4. CoreML export pipelines exist.
5. MLX integration exists.
6. Local LLM integration exists.
7. User feedback pipelines exist.
8. Personalization layer exists.
9. Incremental retraining exists.
10. Swift inference code contains no primary rule engine.
11. All intelligence originates from trainable models.
12. Models can continuously improve over time.
