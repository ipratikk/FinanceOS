import Foundation

/// Read/write access to the knowledge graph — nodes and edges.
/// All writes are idempotent: upsert semantics with weight accumulation on edges.
public protocol GraphRepository: Sendable {
    // MARK: Nodes

    func upsertNode(_ node: GraphNode) async throws -> GraphNode
    func node(id: String) async throws -> GraphNode?
    func node(externalId: String, type: GraphNode.NodeType) async throws -> GraphNode?
    func nodes(ofType type: GraphNode.NodeType) async throws -> [GraphNode]

    // MARK: Edges

    /// Insert edge if absent; if present, increment observationCount and update lastObservedAt.
    func upsertEdge(_ edge: GraphEdge) async throws -> GraphEdge
    func edges(from nodeId: String) async throws -> [GraphEdge]
    func edges(to nodeId: String) async throws -> [GraphEdge]
    func edges(from nodeId: String, type: GraphEdge.EdgeType) async throws -> [GraphEdge]

    // MARK: Queries

    func neighbors(of nodeId: String) async throws -> [GraphNode]
    func neighbors(of nodeId: String, edgeType: GraphEdge.EdgeType) async throws -> [GraphNode]

    // MARK: Bulk Reads (for dev-mode inspector, limited to 1000 rows)

    func allNodes(limit: Int) async throws -> [GraphNode]
    func allEdges(limit: Int) async throws -> [GraphEdge]

    // MARK: Mutations

    func updateNode(_ node: GraphNode) async throws
    func deleteNode(id: String) async throws
    func deleteEdge(id: String) async throws
}
