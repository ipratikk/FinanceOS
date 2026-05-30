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
        let now = Date()

        // 1. Transaction node
        let txnNode = try await store.upsertNode(GraphNode(
            nodeType: .transaction,
            externalId: txn.id.uuidString,
            label: txn.description
        ))

        // 2. Merchant or Person node + directional edge
        if let personId = txn.resolvedPersonId {
            let person = try await store.upsertNode(GraphNode(
                nodeType: .person,
                externalId: personId,
                label: enriched.merchantCandidate.canonicalName
            ))
            let edgeType: GraphEdge.EdgeType = txn.transactionType == .debit ? .paidTo : .paidFrom
            _ = try await store.upsertEdge(GraphEdge(
                fromNodeId: txnNode.id,
                toNodeId: person.id,
                edgeType: edgeType,
                lastObservedAt: txn.postedAt
            ))
        } else {
            let merchantNode = try await store.upsertNode(GraphNode(
                nodeType: .merchant,
                externalId: enriched.merchantCandidate.canonicalName.lowercased(),
                label: enriched.merchantCandidate.canonicalName
            ))
            let edgeType: GraphEdge.EdgeType = txn.transactionType == .debit ? .paidTo : .paidFrom
            _ = try await store.upsertEdge(GraphEdge(
                fromNodeId: txnNode.id,
                toNodeId: merchantNode.id,
                edgeType: edgeType,
                lastObservedAt: txn.postedAt
            ))

            // 3. Category edge (merchant → category)
            let categoryId = enriched.categoryPrediction.categoryId
            let catNode = try await store.upsertNode(GraphNode(
                nodeType: .category,
                externalId: categoryId,
                label: enriched.categoryPrediction.displayName
            ))
            _ = try await store.upsertEdge(GraphEdge(
                fromNodeId: merchantNode.id,
                toNodeId: catNode.id,
                edgeType: .classifiedAs,
                lastObservedAt: now
            ))
        }

        // 4. Account node
        if let ledgerId = txn.ledgerId {
            let accountNode = try await store.upsertNode(GraphNode(
                nodeType: .account,
                externalId: ledgerId.uuidString,
                label: ledgerId.uuidString
            ))
            _ = try await store.upsertEdge(GraphEdge(
                fromNodeId: txnNode.id,
                toNodeId: accountNode.id,
                edgeType: .belongsTo,
                lastObservedAt: txn.postedAt
            ))
        }
    }
}

private extension Transaction {
    var resolvedPersonId: String? { nil }
}
