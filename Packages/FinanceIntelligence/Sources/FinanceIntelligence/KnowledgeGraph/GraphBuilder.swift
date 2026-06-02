import FinanceCore
import Foundation

/// Builds and updates the knowledge graph from enriched transactions.
/// Called after each import batch as a background task.
/// All writes are idempotent — safe to re-run on the same transaction set.
///
/// Uses a two-pass batch strategy:
///   Pass 1: Collect all node descriptors (pure computation, no I/O)
///   Pass 2: Upsert all nodes in one SQLite transaction, then all edges in one transaction
/// This replaces O(N×6) individual writes with 2 writes regardless of batch size.
public struct GraphBuilder: Sendable {
    private let store: GraphStore

    public init(store: GraphStore) {
        self.store = store
    }

    public func build(from transactions: [EnrichedTransaction]) async throws {
        guard !transactions.isEmpty else { return }

        // Pass 1: collect all node/edge descriptors without any I/O.
        var nodeSpecs: [String: NodeSpec] = [:]
        var edgeSpecs: [EdgeSpec] = []

        for enriched in transactions {
            let txn = enriched.transaction
            let txnKey = NodeSpec.key(.transaction, txn.id.uuidString)
            nodeSpecs[txnKey] = NodeSpec(type: .transaction, externalId: txn.id.uuidString, label: txn.description)

            let edgeType: GraphEdge.EdgeType = txn.transactionType == .debit ? .paidTo : .paidFrom

            if let personId = enriched.resolvedEntities?.personId {
                let personKey = NodeSpec.key(.person, personId.uuidString)
                nodeSpecs[personKey] = NodeSpec(
                    type: .person, externalId: personId.uuidString,
                    label: enriched.merchantCandidate.canonicalName
                )
                edgeSpecs.append(EdgeSpec(fromKey: txnKey, toKey: personKey, type: edgeType, date: txn.postedAt))
            } else {
                let merchantExtId = enriched.merchantCandidate.canonicalName.lowercased()
                let merchantKey = NodeSpec.key(.merchant, merchantExtId)
                nodeSpecs[merchantKey] = NodeSpec(
                    type: .merchant, externalId: merchantExtId,
                    label: enriched.merchantCandidate.canonicalName
                )
                edgeSpecs.append(EdgeSpec(fromKey: txnKey, toKey: merchantKey, type: edgeType, date: txn.postedAt))

                let catId = enriched.categoryPrediction.categoryId
                let catKey = NodeSpec.key(.category, catId)
                nodeSpecs[catKey] = NodeSpec(
                    type: .category, externalId: catId,
                    label: enriched.categoryPrediction.displayName
                )
                edgeSpecs.append(EdgeSpec(fromKey: merchantKey, toKey: catKey, type: .classifiedAs, date: txn.postedAt))
            }

            if let ledgerId = txn.ledgerId {
                let accountKey = NodeSpec.key(.account, ledgerId.uuidString)
                nodeSpecs[accountKey] = NodeSpec(
                    type: .account, externalId: ledgerId.uuidString,
                    label: ledgerId.uuidString
                )
                edgeSpecs.append(EdgeSpec(fromKey: txnKey, toKey: accountKey, type: .belongsTo, date: txn.postedAt))
            }
        }

        // Pass 2a: batch upsert all nodes — 1 SQLite transaction.
        let nodes = nodeSpecs.values.map { s in GraphNode(nodeType: s.type, externalId: s.externalId, label: s.label) }
        let upserted = try await store.upsertNodesBatch(nodes)
        let idMap = Dictionary(uniqueKeysWithValues: upserted.map { n in
            (NodeSpec.key(n.nodeType, n.externalId), n.id)
        })

        // Pass 2b: batch upsert all edges — 1 SQLite transaction.
        let edges = edgeSpecs.compactMap { spec -> GraphEdge? in
            guard let fromId = idMap[spec.fromKey], let toId = idMap[spec.toKey] else { return nil }
            return GraphEdge(fromNodeId: fromId, toNodeId: toId, edgeType: spec.type, lastObservedAt: spec.date)
        }
        try await store.upsertEdgesBatch(edges)
    }

    // MARK: - Private helpers

    private struct NodeSpec {
        let type: GraphNode.NodeType
        let externalId: String
        let label: String
        static func key(_ type: GraphNode.NodeType, _ externalId: String) -> String {
            "\(type.rawValue):\(externalId)"
        }
    }

    private struct EdgeSpec {
        let fromKey: String
        let toKey: String
        let type: GraphEdge.EdgeType
        let date: Date
    }
}
