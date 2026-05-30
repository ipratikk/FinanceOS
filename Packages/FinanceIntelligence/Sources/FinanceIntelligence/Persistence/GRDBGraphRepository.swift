import Foundation
import GRDB

/// GRDB-backed implementation of `GraphRepository`.
/// Uses upsert with conflict resolution for nodes; increments edge weight on conflict.
public struct GRDBGraphRepository: GraphRepository {
    private let dbWriter: any DatabaseWriter

    public init(dbWriter: any DatabaseWriter) {
        self.dbWriter = dbWriter
    }

    // MARK: - Nodes

    public func upsertNode(_ node: GraphNode) async throws -> GraphNode {
        // Find-or-create: stable id keyed on (nodeType, externalId).
        // INSERT OR REPLACE would regenerate the UUID, orphaning existing edges.
        try await dbWriter.write { db in
            if let existing = try GRDBGraphNode
                .filter(Column("externalId") == node.externalId &&
                        Column("nodeType") == node.nodeType.rawValue)
                .fetchOne(db),
               let domain = existing.toDomain() {
                return domain
            }
            let grdb = GRDBGraphNode(from: node)
            try grdb.insert(db)
            return node
        }
    }

    public func node(id: String) async throws -> GraphNode? {
        try await dbWriter.read { db in
            try GRDBGraphNode
                .filter(Column("id") == id)
                .fetchOne(db)?
                .toDomain()
        }
    }

    public func node(externalId: String, type: GraphNode.NodeType) async throws -> GraphNode? {
        try await dbWriter.read { db in
            try GRDBGraphNode
                .filter(Column("externalId") == externalId && Column("nodeType") == type.rawValue)
                .fetchOne(db)?
                .toDomain()
        }
    }

    public func nodes(ofType type: GraphNode.NodeType) async throws -> [GraphNode] {
        try await dbWriter.read { db in
            try GRDBGraphNode
                .filter(Column("nodeType") == type.rawValue)
                .fetchAll(db)
                .compactMap { $0.toDomain() }
        }
    }

    // MARK: - Edges

    public func upsertEdge(_ edge: GraphEdge) async throws -> GraphEdge {
        try await dbWriter.write { db in
            let existing = try GRDBGraphEdge
                .filter(
                    Column("fromNodeId") == edge.fromNodeId &&
                    Column("toNodeId") == edge.toNodeId &&
                    Column("edgeType") == edge.edgeType.rawValue
                )
                .fetchOne(db)

            if var found = existing {
                found.observationCount += 1
                found.weight = min(found.weight + 0.1, 10.0)
                found.lastObservedAt = edge.lastObservedAt
                try found.update(db)
                return found.toDomain() ?? edge
            } else {
                let grdb = GRDBGraphEdge(from: edge)
                try grdb.insert(db)
                return edge
            }
        }
    }

    public func edges(from nodeId: String) async throws -> [GraphEdge] {
        try await dbWriter.read { db in
            try GRDBGraphEdge
                .filter(Column("fromNodeId") == nodeId)
                .fetchAll(db)
                .compactMap { $0.toDomain() }
        }
    }

    public func edges(to nodeId: String) async throws -> [GraphEdge] {
        try await dbWriter.read { db in
            try GRDBGraphEdge
                .filter(Column("toNodeId") == nodeId)
                .fetchAll(db)
                .compactMap { $0.toDomain() }
        }
    }

    public func edges(from nodeId: String, type: GraphEdge.EdgeType) async throws -> [GraphEdge] {
        try await dbWriter.read { db in
            try GRDBGraphEdge
                .filter(Column("fromNodeId") == nodeId && Column("edgeType") == type.rawValue)
                .fetchAll(db)
                .compactMap { $0.toDomain() }
        }
    }

    // MARK: - Queries

    public func neighbors(of nodeId: String) async throws -> [GraphNode] {
        try await dbWriter.read { db in
            let edgeRows = try GRDBGraphEdge
                .filter(Column("fromNodeId") == nodeId)
                .fetchAll(db)
            let neighborIds = edgeRows.map(\.toNodeId)
            guard !neighborIds.isEmpty else { return [] }
            return try GRDBGraphNode
                .filter(neighborIds.contains(Column("id")))
                .fetchAll(db)
                .compactMap { $0.toDomain() }
        }
    }

    public func neighbors(of nodeId: String, edgeType: GraphEdge.EdgeType) async throws -> [GraphNode] {
        try await dbWriter.read { db in
            let edgeRows = try GRDBGraphEdge
                .filter(Column("fromNodeId") == nodeId && Column("edgeType") == edgeType.rawValue)
                .fetchAll(db)
            let neighborIds = edgeRows.map(\.toNodeId)
            guard !neighborIds.isEmpty else { return [] }
            return try GRDBGraphNode
                .filter(neighborIds.contains(Column("id")))
                .fetchAll(db)
                .compactMap { $0.toDomain() }
        }
    }
}
