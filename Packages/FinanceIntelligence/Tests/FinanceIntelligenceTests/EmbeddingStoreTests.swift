@testable import FinanceIntelligence
import Foundation
import GRDB
import Testing

@Suite("EmbeddingStore + ANNIndex")
struct EmbeddingStoreTests {
    // MARK: - Helpers

    private func makeStore() throws -> GRDBEmbeddingStore {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("test_embeddings") { db in
            try db.create(table: "transaction_embeddings") { t in
                t.column("transactionId", .text).primaryKey()
                t.column("label", .text).notNull()
                t.column("embeddingBlob", .blob).notNull()
                t.column("modelVersion", .text).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
        }
        let queue = try DatabaseQueue()
        try migrator.migrate(queue)
        return GRDBEmbeddingStore(dbQueue: queue)
    }

    private func makeEmbedding(id: String, label: String, dim: Int = 4) -> StoredEmbedding {
        let vector = (0 ..< dim).map { Float($0) / Float(dim) }
        return StoredEmbedding(
            transactionId: id, label: label,
            vector: vector, modelVersion: "test-v0.1"
        )
    }

    // MARK: - EmbeddingStore

    @Test("Upsert and retrieve embedding round-trips correctly")
    func embeddingStoreRoundTrip() async throws {
        let store = try makeStore()
        let emb = makeEmbedding(id: "tx-1", label: "Swiggy")
        try await store.upsert(emb)
        let retrieved = try await store.embedding(for: "tx-1")
        #expect(retrieved?.transactionId == "tx-1")
        #expect(retrieved?.label == "Swiggy")
        #expect(retrieved?.vector.count == 4)
        #expect(retrieved?.modelVersion == "test-v0.1")
    }

    @Test("Upsert replaces existing embedding")
    func embeddingStoreUpsertReplaces() async throws {
        let store = try makeStore()
        try await store.upsert(makeEmbedding(id: "tx-1", label: "OldLabel"))
        let updated = StoredEmbedding(
            transactionId: "tx-1", label: "NewLabel",
            vector: [0.5, 0.5, 0, 0], modelVersion: "v2"
        )
        try await store.upsert(updated)
        let retrieved = try await store.embedding(for: "tx-1")
        #expect(retrieved?.label == "NewLabel")
        #expect(retrieved?.modelVersion == "v2")
        #expect(try await store.count() == 1)
    }

    @Test("allEmbeddings returns all stored records")
    func embeddingStoreAllEmbeddings() async throws {
        let store = try makeStore()
        try await store.upsert(makeEmbedding(id: "tx-1", label: "A"))
        try await store.upsert(makeEmbedding(id: "tx-2", label: "B"))
        try await store.upsert(makeEmbedding(id: "tx-3", label: "C"))
        let all = try await store.allEmbeddings()
        #expect(all.count == 3)
    }

    @Test("Delete removes embedding")
    func embeddingStoreDelete() async throws {
        let store = try makeStore()
        try await store.upsert(makeEmbedding(id: "tx-1", label: "A"))
        try await store.delete(transactionId: "tx-1")
        #expect(try await store.count() == 0)
        #expect(try await store.embedding(for: "tx-1") == nil)
    }

    @Test("Missing embedding returns nil")
    func embeddingStoreMissing() async throws {
        let store = try makeStore()
        let result = try await store.embedding(for: "nonexistent")
        #expect(result == nil)
    }

    // MARK: - ANNIndex

    @Test("ANNIndex nearest returns closest embedding")
    func annIndexNearest() async throws {
        let store = try makeStore()
        let e1 = StoredEmbedding(transactionId: "t1", label: "Swiggy", vector: [1, 0, 0, 0], modelVersion: "v1")
        let e2 = StoredEmbedding(transactionId: "t2", label: "Blinkit", vector: [0, 1, 0, 0], modelVersion: "v1")
        let e3 = StoredEmbedding(transactionId: "t3", label: "Swiggy2", vector: [0.9, 0.1, 0, 0], modelVersion: "v1")
        try await store.upsert(e1)
        try await store.upsert(e2)
        try await store.upsert(e3)

        let index = ANNIndex(store: store)
        let results = try await index.nearest(to: [1, 0, 0, 0], topK: 2)
        #expect(results.first?.entityId == "t1")
        #expect((results.first?.similarity ?? 0) > 0.9)
    }

    @Test("ANNIndex insert updates index without rebuild")
    func annIndexInsert() async throws {
        let store = try makeStore()
        let index = ANNIndex(store: store)
        try await index.insert(StoredEmbedding(
            transactionId: "t1", label: "A", vector: [1, 0], modelVersion: "v1"
        ))
        try await index.insert(StoredEmbedding(
            transactionId: "t2", label: "B", vector: [0, 1], modelVersion: "v1"
        ))
        #expect(await index.count == 2)
        let results = try await index.nearest(to: [1, 0], topK: 1)
        #expect(results.first?.entityId == "t1")
    }

    @Test("ANNIndex remove deletes from store and index")
    func annIndexRemove() async throws {
        let store = try makeStore()
        let index = ANNIndex(store: store)
        try await index.insert(StoredEmbedding(
            transactionId: "t1", label: "A", vector: [1, 0], modelVersion: "v1"
        ))
        try await index.remove(transactionId: "t1")
        let indexCount = await index.count
        #expect(indexCount == 0)
        #expect(try await store.count() == 0)
    }

    @Test("ANNIndex rebuild loads from store")
    func annIndexRebuild() async throws {
        let store = try makeStore()
        try await store.upsert(StoredEmbedding(
            transactionId: "t1", label: "A", vector: [1, 0], modelVersion: "v1"
        ))
        try await store.upsert(StoredEmbedding(
            transactionId: "t2", label: "B", vector: [0, 1], modelVersion: "v1"
        ))
        let index = ANNIndex(store: store)
        try await index.rebuild()
        #expect(await index.count == 2)
    }

    @Test("ANNIndex lookup latency under 10ms for 1000 entries")
    func annIndexLatency() async throws {
        let store = try makeStore()
        for i in 0 ..< 1000 {
            let vector: [Float] = [Float(i) / 1000, 1 - Float(i) / 1000]
            try await store.upsert(StoredEmbedding(
                transactionId: "t\(i)", label: "L\(i)", vector: vector, modelVersion: "v1"
            ))
        }
        let index = ANNIndex(store: store)
        try await index.rebuild()

        let query: [Float] = [0.5, 0.5]
        let start = Date()
        _ = try await index.nearest(to: query, topK: 5)
        let elapsed = Date().timeIntervalSince(start) * 1000
        #expect(elapsed < 10, "Lookup took \(String(format: "%.1f", elapsed))ms, expected < 10ms")
    }
}
