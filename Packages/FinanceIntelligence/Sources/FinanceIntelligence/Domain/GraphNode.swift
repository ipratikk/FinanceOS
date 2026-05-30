import Foundation

/// A node in the local knowledge graph.
/// Nodes represent financial entities: merchants, persons, transactions, categories, accounts.
public struct GraphNode: Sendable, Codable, Hashable {
    public let id: String
    public let nodeType: NodeType
    /// Foreign key into the entity's primary table (e.g. transactions.id, persons.id).
    public let externalId: String
    /// Display label (merchant canonical name, person canonical name, category display name).
    public let label: String
    /// Arbitrary metadata stored as JSON. Use sparingly — structured queries belong in edges.
    public let properties: [String: String]
    public let createdAt: Date

    public enum NodeType: String, Codable, Sendable, CaseIterable {
        case merchant
        case person
        case transaction
        case category
        case account
        case institution
        case recurringPattern
    }

    public init(
        id: String = UUID().uuidString,
        nodeType: NodeType,
        externalId: String,
        label: String,
        properties: [String: String] = [:],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.nodeType = nodeType
        self.externalId = externalId
        self.label = label
        self.properties = properties
        self.createdAt = createdAt
    }
}
