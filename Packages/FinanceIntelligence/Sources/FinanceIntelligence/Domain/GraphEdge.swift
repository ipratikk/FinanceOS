import Foundation

/// A directed edge in the local knowledge graph.
/// Edges encode financial relationships between entities with confidence-weighted observation counts.
public struct GraphEdge: Sendable, Codable, Hashable {
    public let id: String
    public let fromNodeId: String
    public let toNodeId: String
    public let edgeType: EdgeType
    /// Bayesian-style weight: starts at 1.0, incremented on each corroborating observation.
    public var weight: Double
    /// Number of transactions that contributed to this edge.
    public var observationCount: Int
    public var lastObservedAt: Date
    public let createdAt: Date

    public enum EdgeType: String, Codable, Sendable, CaseIterable {
        case paidTo          = "PAID_TO"
        case paidFrom        = "PAID_FROM"
        case belongsTo       = "BELONGS_TO"
        case classifiedAs    = "CLASSIFIED_AS"
        case recursWith      = "RECURS_WITH"
        case paysRentTo      = "PAYS_RENT_TO"
        case paysCardTo      = "PAYS_CARD_TO"
        case investsWith     = "INVESTS_WITH"
        case relatedTo       = "RELATED_TO"
    }

    public init(
        id: String = UUID().uuidString,
        fromNodeId: String,
        toNodeId: String,
        edgeType: EdgeType,
        weight: Double = 1.0,
        observationCount: Int = 1,
        lastObservedAt: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.fromNodeId = fromNodeId
        self.toNodeId = toNodeId
        self.edgeType = edgeType
        self.weight = weight
        self.observationCount = observationCount
        self.lastObservedAt = lastObservedAt
        self.createdAt = createdAt
    }
}
