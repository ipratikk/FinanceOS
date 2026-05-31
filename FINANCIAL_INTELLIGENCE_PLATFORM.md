You are the Principal Architect for FinanceOS.

FinanceOS is a privacy-first personal finance platform built using:

- Swift 6
- SwiftUI
- Observation
- Combine
- GRDB
- SQLite
- CoreML
- Apple Intelligence
- Shared Swift Packages
- iOS + macOS

The application already has a modular architecture:

FinanceApp
 ├── FinanceUI
 ├── FinanceCore
 ├── FinanceParsers
 ├── FinanceDatabase
 ├── FinanceAnalytics
 └── FinanceDesignSystem

The UI layer must remain completely decoupled from:

- GRDB
- SQLite
- CoreML
- Parsing logic
- Apple Intelligence
- External frameworks

The UI communicates only through ViewModels and domain models.

====================================================
DEVELOPMENT BRANCH
====================================================

Base branch: feat/financial-intelligence-platform

All implementation work for this platform must branch from and merge back into:

  feat/financial-intelligence-platform

Do NOT branch from or merge directly into main.

====================================================
MISSION
====================================================

Build a production-grade Transaction Intelligence Platform that achieves GPT/Claude-level transaction understanding while remaining:

- Mostly offline
- Explainable
- Deterministic
- Privacy-first
- Auditable
- Incrementally trainable
- Maintainable for 5+ years

The system must become smarter every time a user imports a new statement.

The intelligence platform will become the core competitive advantage of FinanceOS.

====================================================
CORE PHILOSOPHY
====================================================

The system must NOT rely on LLMs for classification.

The intelligence pipeline must follow:

Rule Engine
→ Entity Resolution
→ Historical Analysis
→ Knowledge Graph
→ CoreML Models
→ Apple Intelligence Language Generation

Apple Intelligence must NEVER decide:

- Category
- Merchant
- Intent
- Relationship
- Recurring status

Apple Intelligence should only convert structured intelligence into natural language.

====================================================
TARGET CAPABILITIES
====================================================

The platform must understand:

----------------------------------------------------
MERCHANTS
----------------------------------------------------

Examples:

UPI-AMERICAN EXPRESS-AEBC373...
AMEX
AEBC373008620701005

↓

American Express

Examples:

ZEPTO
ZEPTO MARKETPLACE
CF.ZEPTOMARKETPLACE

↓

Zepto

Build:

Merchant Resolution
Merchant Linking
Merchant Alias Detection
Merchant Embeddings
Merchant Confidence Scoring

----------------------------------------------------
TRANSACTION INTENTS
----------------------------------------------------

The platform must distinguish:

Salary
Rent
Investment
Insurance
Subscription
Credit Card Payment
Cash Withdrawal
Refund
Cashback
Transfer
Loan Payment
Interest Payment
Utility Bill
Shopping
Groceries
Food
Travel
Healthcare
Income
Unknown

Intent is different from category.

Example:

American Express

Category:
Finance

Intent:
Credit Card Payment

----------------------------------------------------
RELATIONSHIP DETECTION
----------------------------------------------------

The system must infer relationships from behavior.

Example:

Ritik Gupta

₹22,000
Monthly
After salary

↓

Likely landlord / rent recipient

Example:

Aman Pandey

Frequently sends money

↓

Friend
Reimbursement source

Example:

Seema Goel

Large recurring transfers

↓

Family transfer relationship

Relationship confidence must be continuously updated.

----------------------------------------------------
RECURRING DETECTION
----------------------------------------------------

Detect:

Weekly
Monthly
Quarterly
Yearly

Use:

Amount similarity
Date similarity
Merchant similarity
Behavior similarity

Examples:

Spotify
Max Life
Rent
EMIs
SIPs

Generate recurring confidence scores.

----------------------------------------------------
FINANCIAL BEHAVIOR INTELLIGENCE
----------------------------------------------------

Learn:

Salary cycles

Rent cycles

Credit card payoff cycles

Investment cycles

Subscription cycles

Cash flow patterns

Spending behavior

Income consistency

Savings behavior

Financial routines

Example:

Salary
→ Rent
→ Credit Cards
→ SIPs

This should become a learned financial pattern.

----------------------------------------------------
KNOWLEDGE GRAPH
----------------------------------------------------

Build a local graph engine.

Nodes:

Merchant
Person
Transaction
Category
Account
Institution
RecurringPattern

Relationships:

PAID_TO
PAID_FROM
BELONGS_TO
RELATED_TO
RECURS_WITH
CLASSIFIED_AS
WORKS_FOR
PAYS_RENT_TO
PAYS_CARD_TO
INVESTS_WITH

The graph must persist in SQLite through GRDB.

The graph must support:

Entity linking

Relationship inference

Behavior inference

Description generation

Recommendation systems

Future AI agents

----------------------------------------------------
DESCRIPTION GENERATION
----------------------------------------------------

Descriptions must be generated from structured intelligence.

BAD:

"UPI-AMERICAN EXPRESS-AEBC373..."

GOOD:

"Monthly American Express credit card payment"

BAD:

"ACH D INDIAN CLEARING CORP"

GOOD:

"Monthly mutual fund SIP contribution"

BAD:

"UPI-RITIK GUPTA"

GOOD:

"Monthly rent payment"

Descriptions should be:

Short
Natural
Consistent
Human-readable
Deterministic

Apple Intelligence should receive:

Merchant
Intent
Relationship
Recurring Status
Confidence
Behavior Context

and only generate language.

====================================================
FINANCEOS PACKAGE STRUCTURE
====================================================

Create a new package:

FinanceIntelligence

Structure:

FinanceIntelligence
│
├── Domain
│
├── MerchantIntelligence
│   ├── MerchantResolver
│   ├── MerchantNormalizer
│   ├── AliasResolver
│   ├── EmbeddingIndex
│   └── ConfidenceScorer
│
├── Categorization
│   ├── CategoryEngine
│   ├── IntentEngine
│   └── RuleEngine
│
├── Recurring
│   ├── RecurringDetector
│   ├── PatternAnalyzer
│   └── ScheduleInference
│
├── Relationships
│   ├── PersonResolver
│   ├── RelationshipEngine
│   └── RelationshipClassifier
│
├── KnowledgeGraph
│   ├── GraphStore
│   ├── GraphQueries
│   ├── GraphBuilder
│   └── GraphAlgorithms
│
├── Behavior
│   ├── SalaryAnalyzer
│   ├── SpendingAnalyzer
│   ├── CashflowAnalyzer
│   └── FinancialRoutineDetector
│
├── MachineLearning
│   ├── MerchantClassifier
│   ├── CategoryClassifier
│   ├── RelationshipClassifier
│   ├── EmbeddingGenerator
│   └── ModelManager
│
├── DescriptionGeneration
│   ├── DescriptionContext
│   ├── DescriptionGenerator
│   ├── AppleIntelligenceAdapter
│   └── FallbackGenerator
│
└── Persistence
    ├── Repositories
    ├── GRDBModels
    ├── Migrations
    └── Caches

====================================================
COREML STRATEGY
====================================================

Build separate models.

1. Merchant Classifier

Input:
Raw Narration

Output:
Merchant ID

----------------------------------------------------

2. Category Classifier

Input:

Merchant
Amount
Direction
Channel

Output:

Transaction Category

----------------------------------------------------

3. Relationship Classifier

Input:

Person
Frequency
Average Amount
Timing

Output:

Friend
Family
Landlord
Employer
Loan
Unknown

----------------------------------------------------

4. Embedding Generator

Generate vector embeddings for:

Merchants
Narrations
People

Support fuzzy matching and clustering.

----------------------------------------------------

5. Incremental Training

New statements should generate new training data automatically.

Models must support retraining without losing historical intelligence.

====================================================
DATABASE REQUIREMENTS
====================================================

Design GRDB schema for:

Transactions
Merchants
MerchantAliases
Persons
Relationships
RecurringPatterns
Embeddings
KnowledgeGraphNodes
KnowledgeGraphEdges
ModelMetadata

Requirements:

100,000+ transactions

10,000+ merchants

Sub-second merchant lookup

Fast graph traversal

Offline-first

Migration-safe

====================================================
ENGINEERING REQUIREMENTS
====================================================

Use:

Protocols
Dependency Injection
Sendable
Actors where appropriate
Structured Concurrency
Observation
Combine

Avoid:

Singletons
Massive services
Tight coupling
UI dependencies

Everything must be testable.

====================================================
OUTPUT REQUIRED
====================================================

Generate:

1. Complete system architecture
2. High-level design
3. Low-level design
4. Miro-style diagrams
5. Package structure
6. Domain models
7. Repository interfaces
8. GRDB schema
9. CoreML architecture
10. Knowledge graph design
11. Intelligence pipeline
12. Sequence diagrams
13. Example Swift implementations
14. Testing strategy
15. Migration strategy
16. Performance strategy
17. Incremental learning strategy
18. Apple Intelligence integration strategy
19. Risk analysis
20. Recommended implementation roadmap

Assume this intelligence platform will become the foundation for future features including:

- AI financial assistant
- Spending insights
- Budgeting
- Subscription management
- Fraud detection
- Cash flow forecasting
- Financial recommendations
- Autonomous finance workflows

Design for long-term extensibility and production-scale quality.

Before implementing any CoreML model, maximize deterministic intelligence first.

Target accuracy:

Rules + Linking + Graph + Historical Analysis > 90%

CoreML should improve the remaining unknown cases.

LLMs should contribute only language generation, never core financial intelligence.