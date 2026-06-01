import Foundation

/// Provenance metadata written to a transaction after an intelligence pipeline pass.
/// Nil fields are treated as "no update" — existing column values are preserved.
public struct EnrichmentProvenance: Sendable {
    public let categoryId: String?
    public let merchantName: String?
    public let intentId: String?
    public let resolvedPersonId: String?
    public let lastEnrichedAt: Date
    public let intelligenceSource: String?
    public let intelligenceModelVersion: String?
    public let intelligenceConfigVersion: String?

    public init(
        categoryId: String? = nil,
        merchantName: String? = nil,
        intentId: String? = nil,
        resolvedPersonId: String? = nil,
        lastEnrichedAt: Date = Date(),
        intelligenceSource: String? = nil,
        intelligenceModelVersion: String? = nil,
        intelligenceConfigVersion: String? = nil
    ) {
        self.categoryId = categoryId
        self.merchantName = merchantName
        self.intentId = intentId
        self.resolvedPersonId = resolvedPersonId
        self.lastEnrichedAt = lastEnrichedAt
        self.intelligenceSource = intelligenceSource
        self.intelligenceModelVersion = intelligenceModelVersion
        self.intelligenceConfigVersion = intelligenceConfigVersion
    }
}
