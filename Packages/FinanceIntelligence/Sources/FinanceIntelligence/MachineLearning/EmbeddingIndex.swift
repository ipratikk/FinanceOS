import Foundation

/// In-memory nearest-neighbor index over embedding vectors.
/// Uses brute-force cosine similarity (dot product on L2-normalized vectors).
/// Viable for up to ~10,000 merchants at 64 dimensions (~2.5 MB).
public struct EmbeddingIndex: Sendable {
    /// A nearest-neighbor result with entity identity and cosine similarity score.
    public struct NearestResult: Sendable {
        public let entityId: String
        public let label: String
        public let similarity: Float
    }

    private struct Entry {
        let entityId: String
        let label: String
        let vector: [Float]
    }

    private var entries: [Entry] = []

    public init() {}

    public var count: Int {
        entries.count
    }

    /// Add or replace a vector for the given entity.
    public mutating func upsert(entityId: String, label: String, vector: [Float]) {
        entries.removeAll { $0.entityId == entityId }
        entries.append(Entry(entityId: entityId, label: label, vector: vector))
    }

    /// Remove all entries for the given entity.
    public mutating func remove(entityId: String) {
        entries.removeAll { $0.entityId == entityId }
    }

    /// Find the top-k nearest neighbors by cosine similarity (dot product of L2-normalized vectors).
    /// Returns results sorted by similarity descending.
    public func nearest(to query: [Float], topK: Int = 5) -> [NearestResult] {
        guard !entries.isEmpty, query.count == entries.first?.vector.count else { return [] }
        return entries
            .map { NearestResult(entityId: $0.entityId, label: $0.label, similarity: dotProduct(query, $0.vector)) }
            .sorted { $0.similarity > $1.similarity }
            .prefix(topK)
            .map(\.self)
    }

    /// Cosine similarity between two L2-normalized vectors = dot product.
    public func similarity(a: [Float], b: [Float]) -> Float {
        dotProduct(a, b)
    }

    // MARK: - Private

    private func dotProduct(_ a: [Float], _ b: [Float]) -> Float {
        zip(a, b).reduce(0) { $0 + $1.0 * $1.1 }
    }
}
