import Foundation

/// Actor-isolated facade over `GraphRepository`.
/// Single point of access for all knowledge graph operations from the intelligence pipeline.
public actor GraphStore {
    private let repository: any GraphRepository

    public init(repository: any GraphRepository) {
        self.repository = repository
    }

    // MARK: - Node Access

    public func upsertNode(_ node: GraphNode) async throws -> GraphNode {
        try await repository.upsertNode(node)
    }

    public func node(externalId: String, type: GraphNode.NodeType) async throws -> GraphNode? {
        try await repository.node(externalId: externalId, type: type)
    }

    public func nodes(ofType type: GraphNode.NodeType) async throws -> [GraphNode] {
        try await repository.nodes(ofType: type)
    }

    // MARK: - Edge Access

    public func upsertEdge(_ edge: GraphEdge) async throws -> GraphEdge {
        try await repository.upsertEdge(edge)
    }

    public func edges(from nodeId: String) async throws -> [GraphEdge] {
        try await repository.edges(from: nodeId)
    }

    // MARK: - Neighbor Queries

    public func neighbors(of nodeId: String) async throws -> [GraphNode] {
        try await repository.neighbors(of: nodeId)
    }

    public func neighbors(of nodeId: String, edgeType: GraphEdge.EdgeType) async throws -> [GraphNode] {
        try await repository.neighbors(of: nodeId, edgeType: edgeType)
    }

    // MARK: - BFS Traversal

    /// Breadth-first traversal up to `maxDepth` hops. Returns all reachable nodes, excluding start.
    public func bfsNeighbors(of startNodeId: String, maxDepth: Int = 2) async throws -> [GraphNode] {
        var visited: Set<String> = [startNodeId]
        var queue: [(nodeId: String, depth: Int)] = [(startNodeId, 0)]
        var result: [GraphNode] = []

        while !queue.isEmpty {
            let (currentId, depth) = queue.removeFirst()
            guard depth < maxDepth else { continue }

            let neighbors = try await repository.neighbors(of: currentId)
            for neighbor in neighbors where !visited.contains(neighbor.id) {
                visited.insert(neighbor.id)
                result.append(neighbor)
                queue.append((neighbor.id, depth + 1))
            }
        }
        return result
    }
}
