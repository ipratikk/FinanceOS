---
doc: 016-link-prediction
version: 0.1.0
status: Draft
date: 2026-06-02
---

# Link Prediction — Model 8

## Purpose

Define the complete design for the Link Prediction model. Link prediction identifies latent relationships between financial entities in the knowledge graph that are not yet explicitly connected — predicting that "this salary credit is likely the source of this EMI debit", or "these two peer transfers are likely related". This powers: money flow visualization, financial behavior analysis, and the agent's ability to reason about "where does my money go".

---

## Prerequisites

Model 8 has hard dependencies on:
- **Model 1** (Merchant Recognition) — entity resolution requires canonical merchant names
- **Model 7** (Embedding Model) — entity embeddings are the primary input features
- **KnowledgeGraph** — existing edges define training positive examples

Model 8 is a Phase 4 deliverable. Do not begin implementation until Models 1 and 7 are deployed.

---

## Knowledge Graph Entity Types

```
Entities:
  Transaction (id, amount, date, direction)
  Merchant    (canonicalName, category)
  Person      (name, vpa)
  Account     (accountId, bank)
  Category    (name)
  Intent      (name)

Edge Types:
  Transaction → Merchant     (PAID_TO / RECEIVED_FROM)
  Transaction → Category     (CATEGORIZED_AS)
  Transaction → Intent       (HAS_INTENT)
  Transaction → Person       (SENT_TO / RECEIVED_FROM)
  Transaction → Account      (FROM_ACCOUNT / TO_ACCOUNT)
  Merchant    → Category     (BELONGS_TO)
  Transaction → Transaction  (LIKELY_RELATED)  ← Model 8 adds these
```

---

## Link Types Model 8 Predicts

| Link | Description | Example |
|---|---|---|
| `SALARY_TO_RENT` | Salary credit followed by rent debit | ₹85K salary → ₹25K rent next day |
| `SALARY_TO_CREDIT_CARD` | Salary → credit card bill payment | ₹85K salary → ₹12K CC payment |
| `SALARY_TO_SIP` | Salary → SIP investment | ₹85K salary → ₹5K Zerodha SIP |
| `SALARY_TO_INSURANCE` | Salary → insurance premium | ₹85K salary → ₹2.5K LIC |
| `LIKELY_REFUND` | Purchase → refund (same merchant, ~same amount) | ₹1,299 Amazon → ₹1,299 Amazon credit |
| `RELATED_TRANSFER` | Outbound → inbound (round-trip money) | ₹10K sent → ₹9,500 received next week |
| `EMI_CHAIN` | Recurring EMI payments as a chain | Jan EMI → Feb EMI → Mar EMI |
| `SUBSCRIPTION_CHAIN` | Recurring subscription as a chain | Netflix Jan → Netflix Feb → Netflix Mar |

---

## Architecture: Knowledge Graph Embedding

```
Entity embeddings (from Model 7 + learned graph embeddings)
          │
          ▼
[TransE-style embedding model]
  Optimization: ||h + r - t||₂ minimized for (head, relation, tail) triples
          │
          ▼
Score function: f(h, r, t) = -||h + r - t||₂
Higher score = more likely edge exists
          │
          ▼
[Sigmoid for confidence]
  confidence = sigmoid(f(h, r, t))
```

### Why TransE

- Simple, computationally efficient on-device
- Works well for hierarchical and chain relationships (salary → obligations chain)
- MLX implementation is straightforward
- Limitation: cannot model symmetric or N-ary relationships well → acceptable for financial graph

---

## Training Data Construction

### Positive Examples

From existing `KnowledgeGraph` edges:

```python
def build_positive_triples(graph_db) -> list[Triple]:
    """Extract (head, relation, tail) from existing graph edges."""
    triples = []
    
    # Salary → obligation triples
    salary_transactions = query_by_intent(graph_db, "receiveSalary")
    for salary_txn in salary_transactions:
        obligations = query_same_month_obligations(graph_db, salary_txn)
        for obligation in obligations:
            rel = classify_salary_obligation_relation(obligation.intent)
            triples.append(Triple(salary_txn.id, rel, obligation.id))
    
    # Purchase → refund triples
    refund_transactions = query_by_intent(graph_db, "receiveRefund")
    for refund in refund_transactions:
        purchase = find_matching_purchase(graph_db, refund)
        if purchase:
            triples.append(Triple(purchase.id, "LIKELY_REFUND", refund.id))
    
    return triples
```

### Negative Examples

Random negative sampling: for each positive triple (h, r, t), generate corrupted negatives by replacing h or t with a random entity.

Ratio: 5 negatives per positive (standard in graph embedding literature).

---

## MLX Implementation

```swift
// LinkPrediction/MLXLinkPredictor.swift

public final class MLXLinkPredictor: LinkPredictor {
    private let modelPath: URL
    private var entityEmbeddings: [String: [Float]]?  // lazy loaded
    private var relationEmbeddings: [String: [Float]]?

    public init(registry: any ModelRegistry) throws {
        self.modelPath = try registry.mlxArtifactPath(for: .linkPredict)
    }

    public func predict(from source: EntityID,
                        to candidate: EntityID) async -> LinkPrediction {
        await ensureLoaded()
        
        guard let hEmbed = entityEmbeddings?[source.rawValue],
              let tEmbed = entityEmbeddings?[candidate.rawValue] else {
            return LinkPrediction(sourceEntityID: source, targetEntityID: candidate,
                                 relationshipType: .unknown, confidence: 0)
        }
        
        // Score all relation types; return highest confidence
        let scores = RelationshipType.allCases.compactMap { relation -> (RelationshipType, Float)? in
            guard let rEmbed = relationEmbeddings?[relation.rawValue] else { return nil }
            let score = transEScore(h: hEmbed, r: rEmbed, t: tEmbed)
            return (relation, score)
        }
        
        guard let (bestRelation, bestScore) = scores.max(by: { $0.1 < $1.1 }) else {
            return LinkPrediction(sourceEntityID: source, targetEntityID: candidate,
                                 relationshipType: .unknown, confidence: 0)
        }
        
        let confidence = sigmoid(bestScore)
        guard confidence > 0.75 else {
            return LinkPrediction(sourceEntityID: source, targetEntityID: candidate,
                                 relationshipType: .unknown, confidence: confidence)
        }
        
        return LinkPrediction(sourceEntityID: source, targetEntityID: candidate,
                             relationshipType: bestRelation, confidence: confidence)
    }
    
    private func transEScore(h: [Float], r: [Float], t: [Float]) -> Float {
        let diff = zip(zip(h, r), t).map { ($0.0 + $0.1 - $1) }
        let norm = sqrt(diff.map { $0 * $0 }.reduce(0, +))
        return -norm  // higher (less negative) = more likely
    }
}
```

---

## Graph Enrichment Workflow

Link prediction runs asynchronously after each import batch:

```
Import batch complete
        │
        ▼
KnowledgeGraph updated with new Transaction nodes
        │
        ▼
MLXLinkPredictor.suggestEdges(for: newTransactions)
        │
        ▼
Filter suggestions where confidence > 0.75
        │
        ▼
GraphBuilder.addSuggestedEdges(edges, source: .mlPrediction)
        │
        ▼
Edges stored in GraphStore with confidence score
```

---

## Performance Targets

| Metric | Target |
|---|---|
| AUC-ROC | ≥ 0.85 |
| Hits@1 | ≥ 0.65 |
| Hits@10 | ≥ 0.90 |
| MRR | ≥ 0.70 |
| False edge rate (confidence > 0.75) | ≤ 0.10 |
| P95 latency per entity pair | < 10 ms |
| Model size (weights) | < 50 MB |

---

## Training Script

`training/link_prediction/train.py`

```python
# Inputs:  knowledge graph export (JSONL), entity embeddings from Model 7
# Outputs: artifacts/link_predictor_v{version}/
#          - entity_embeddings.npy
#          - relation_embeddings.npy
#          - model_config.json

import torch
from torch.optim import Adam
from models import TransEModel

model = TransEModel(
    num_entities=len(entity_vocab),
    num_relations=len(relation_vocab),
    embedding_dim=128,
    margin=1.0
)

optimizer = Adam(model.parameters(), lr=0.001)

for epoch in range(1000):
    for batch in dataloader:
        pos_triples, neg_triples = batch
        loss = model.margin_loss(pos_triples, neg_triples)
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()
```

---

## Risks

| Risk | Mitigation |
|---|---|
| Insufficient graph density for training | Requires at least 6 months of transaction history per user before prediction quality is acceptable |
| Entity embeddings from Model 7 misaligned with graph structure | Fine-tune entity embeddings jointly with relation embeddings during TransE training |
| False salary→rent links when amounts don't correlate | Add amount-ratio feature to scoring; filter links where amount ratio is implausible |
| MLX dependency + link predictor exceeds memory budget | Unload link predictor when not in active use; lazy load per-session |
| Phase 4 dependency — Models 1 and 7 must be production-quality first | Hard gate: do not begin training until Model 7 ANN recall ≥ 0.90 on held-out set |
