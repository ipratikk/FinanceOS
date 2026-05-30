import FinanceCore
import Foundation

/// Builds and updates the knowledge graph from enriched transactions.
/// Called after each import batch as a background task.
/// All writes are idempotent — safe to re-run on the same transaction set.
public struct GraphBuilder: Sendable {
    private let store: GraphStore

    public init(store: GraphStore) {
        self.store = store
    }

    /// Updates the graph for a batch of enriched transactions.
    /// Creates/updates nodes and edges; increments observation counts on repeated patterns.
    public func build(from transactions: [EnrichedTransaction]) async throws {
        for txn in transactions {
            try await processTransaction(txn)
        }
    }

    // MARK: - Private

    private func processTransaction(_ enriched: EnrichedTransaction) async throws {
        let txn = enriched.transaction
        let txnNode = try await store.upsertNode(GraphNode(
            nodeType: .transaction,
            externalId: txn.id.uuidString,
            label: txn.description
        ))
        try await addPersonOrMerchantEdge(txnNode: txnNode, enriched: enriched)
        try await addAccountEdge(txnNode: txnNode, txn: txn)
    }

    private func addPersonOrMerchantEdge(txnNode: GraphNode, enriched: EnrichedTransaction) async throws {
        let txn = enriched.transaction
        let edgeType: GraphEdge.EdgeType = txn.transactionType == .debit ? .paidTo : .paidFrom
        if let personId = txn.resolvedPersonId {
            let person = try await store.upsertNode(GraphNode(
                nodeType: .person,
                externalId: personId,
                label: enriched.merchantCandidate.canonicalName
            ))
            _ = try await store.upsertEdge(GraphEdge(
                fromNodeId: txnNode.id, toNodeId: person.id,
                edgeType: edgeType, lastObservedAt: txn.postedAt
            ))
        } else {
            let merchantNode = try await store.upsertNode(GraphNode(
                nodeType: .merchant,
                externalId: enriched.merchantCandidate.canonicalName.lowercased(),
                label: enriched.merchantCandidate.canonicalName
            ))
            _ = try await store.upsertEdge(GraphEdge(
                fromNodeId: txnNode.id, toNodeId: merchantNode.id,
                edgeType: edgeType, lastObservedAt: txn.postedAt
            ))
            try await addCategoryEdge(merchantNode: merchantNode, enriched: enriched)
        }
    }

    private func addCategoryEdge(merchantNode: GraphNode, enriched: EnrichedTransaction) async throws {
        let catNode = try await store.upsertNode(GraphNode(
            nodeType: .category,
            externalId: enriched.categoryPrediction.categoryId,
            label: enriched.categoryPrediction.displayName
        ))
        _ = try await store.upsertEdge(GraphEdge(
            fromNodeId: merchantNode.id, toNodeId: catNode.id,
            edgeType: .classifiedAs, lastObservedAt: Date()
        ))
    }

    private func addAccountEdge(txnNode: GraphNode, txn: Transaction) async throws {
        guard let ledgerId = txn.ledgerId else { return }
        let accountNode = try await store.upsertNode(GraphNode(
            nodeType: .account,
            externalId: ledgerId.uuidString,
            label: ledgerId.uuidString
        ))
        _ = try await store.upsertEdge(GraphEdge(
            fromNodeId: txnNode.id, toNodeId: accountNode.id,
            edgeType: .belongsTo, lastObservedAt: txn.postedAt
        ))
    }
}

private extension Transaction {
    var resolvedPersonId: String? {
        nil
    }
}
