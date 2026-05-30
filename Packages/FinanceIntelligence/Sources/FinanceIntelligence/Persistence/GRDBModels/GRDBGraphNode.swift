import Foundation
import GRDB

struct GRDBGraphNode: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "knowledge_graph_nodes"

    var id: String
    var nodeType: String
    var externalId: String
    var label: String
    var properties: String
    var createdAt: Date

    init(from node: GraphNode) {
        id = node.id
        nodeType = node.nodeType.rawValue
        externalId = node.externalId
        label = node.label
        properties = (try? JSONEncoder().encode(node.properties))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        createdAt = node.createdAt
    }

    func toDomain() -> GraphNode? {
        guard let type = GraphNode.NodeType(rawValue: nodeType) else { return nil }
        let props = (properties.data(using: .utf8))
            .flatMap { try? JSONDecoder().decode([String: String].self, from: $0) } ?? [:]
        return GraphNode(
            id: id,
            nodeType: type,
            externalId: externalId,
            label: label,
            properties: props,
            createdAt: createdAt
        )
    }
}
