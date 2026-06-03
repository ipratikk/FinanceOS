import Foundation

/// Approximate nearest-neighbor index over transaction embeddings.
///
/// Builds an in-memory `EmbeddingIndex` from a persistent `EmbeddingStore` for
/// sub-10ms lookup latency. Call `rebuild()` after bulk embedding updates.
public actor ANNIndex {
    private let store: any EmbeddingStore
    private var index: EmbeddingIndex = EmbeddingIndex()
    private var isBuilt: Bool = false

    public init(store: any EmbeddingStore) {
        self.store = store
    }

    /// Load all embeddings from the store and build the in-memory index.
    /// Must be called at least once before using `nearest(to:topK:)`.
    public func rebuild() async throws {
        let embeddings = try await store.allEmbeddings()
        var fresh = EmbeddingIndex()
        for emb in embeddings {
            fresh.upsert(entityId: emb.transactionId, label: emb.label, vector: emb.vector)
        }
        index = fresh
        isBuilt = true
    }

    /// Persist a new embedding and update the in-memory index.
    public func insert(_ embedding: StoredEmbedding) async throws {
        try await store.upsert(embedding)
        index.upsert(entityId: embedding.transactionId, label: embedding.label, vector: embedding.vector)
        isBuilt = true
    }

    /// Find the top-k most similar embeddings to the query vector.
    /// Builds the index on first call if not yet built.
    public func nearest(to query: [Float], topK: Int = 5) async throws -> [EmbeddingIndex.NearestResult] {
        if !isBuilt { try await rebuild() }
        return index.nearest(to: query, topK: topK)
    }

    /// Remove an embedding from both the store and the in-memory index.
    public func remove(transactionId: String) async throws {
        try await store.delete(transactionId: transactionId)
        index.remove(entityId: transactionId)
    }

    /// Number of embeddings currently in the in-memory index.
    public var count: Int {
        index.count
    }

    /// Number of embeddings persisted in the backing store.
    public func persistedCount() async throws -> Int {
        try await store.count()
    }
}
