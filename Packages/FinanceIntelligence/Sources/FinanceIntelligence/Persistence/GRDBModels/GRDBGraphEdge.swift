import Foundation
import GRDB

struct GRDBGraphEdge: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "knowledge_graph_edges"

    var id: String
    var fromNodeId: String
    var toNodeId: String
    var edgeType: String
    var weight: Double
    var observationCount: Int
    var lastObservedAt: Date
    var createdAt: Date

    init(from edge: GraphEdge) {
        id = edge.id
        fromNodeId = edge.fromNodeId
        toNodeId = edge.toNodeId
        edgeType = edge.edgeType.rawValue
        weight = edge.weight
        observationCount = edge.observationCount
        lastObservedAt = edge.lastObservedAt
        createdAt = edge.createdAt
    }

    func toDomain() -> GraphEdge? {
        guard let type = GraphEdge.EdgeType(rawValue: edgeType) else { return nil }
        return GraphEdge(
            id: id,
            fromNodeId: fromNodeId,
            toNodeId: toNodeId,
            edgeType: type,
            weight: weight,
            observationCount: observationCount,
            lastObservedAt: lastObservedAt,
            createdAt: createdAt
        )
    }
}
