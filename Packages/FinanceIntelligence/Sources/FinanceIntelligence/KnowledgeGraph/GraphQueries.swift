import Foundation

/// High-level query helpers over `GraphStore`.
/// Encapsulates common intelligence queries so callers don't construct BFS manually.
public struct GraphQueries: Sendable {
    private let store: GraphStore

    public init(store: GraphStore) {
        self.store = store
    }

    // MARK: - Entity Lookup

    /// Find a merchant node by canonical name.
    public func merchantNode(canonicalName: String) async throws -> GraphNode? {
        try await store.node(externalId: canonicalName.lowercased(), type: .merchant)
    }

    /// Find a person node by person ID.
    public func personNode(personId: String) async throws -> GraphNode? {
        try await store.node(externalId: personId, type: .person)
    }

    // MARK: - Category Signal

    /// Category nodes directly connected to a merchant node via CLASSIFIED_AS edges.
    /// Returns categories sorted by observation count descending (most common first).
    public func categories(for merchantNodeId: String) async throws -> [GraphNode] {
        try await store.neighbors(of: merchantNodeId, edgeType: .classifiedAs)
    }

    // MARK: - Relationship Signals

    /// All persons the user has paid to — basis for relationship inference.
    public func paidToPersons() async throws -> [GraphNode] {
        try await store.nodes(ofType: .person)
    }

    /// Transactions connected to a specific person node.
    public func transactionsInvolving(personNodeId: String) async throws -> [GraphNode] {
        try await store.nodes(ofType: .transaction)
    }

    // MARK: - BFS

    /// Entities reachable from a given node within `maxDepth` hops.
    public func reachable(from nodeId: String, maxDepth: Int = 2) async throws -> [GraphNode] {
        try await store.bfsNeighbors(of: nodeId, maxDepth: maxDepth)
    }
}
