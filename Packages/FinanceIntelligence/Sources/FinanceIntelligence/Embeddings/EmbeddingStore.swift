import Foundation
import GRDB

/// A persisted embedding record for a single transaction.
public struct StoredEmbedding: Sendable {
    public let transactionId: String
    public let label: String
    public let vector: [Float]
    public let modelVersion: String
    public let updatedAt: Date

    public init(transactionId: String, label: String, vector: [Float], modelVersion: String, updatedAt: Date = .now) {
        self.transactionId = transactionId
        self.label = label
        self.vector = vector
        self.modelVersion = modelVersion
        self.updatedAt = updatedAt
    }
}

/// Persistence protocol for transaction embeddings.
public protocol EmbeddingStore: Sendable {
    func upsert(_ embedding: StoredEmbedding) async throws
    func embedding(for transactionId: String) async throws -> StoredEmbedding?
    func allEmbeddings() async throws -> [StoredEmbedding]
    func delete(transactionId: String) async throws
    func count() async throws -> Int
}

/// GRDB-backed `EmbeddingStore` persisting to `transaction_embeddings` table.
public final class GRDBEmbeddingStore: EmbeddingStore, @unchecked Sendable {
    private let dbQueue: any DatabaseWriter

    public init(dbQueue: any DatabaseWriter) {
        self.dbQueue = dbQueue
    }

    public func upsert(_ embedding: StoredEmbedding) async throws {
        let record = GRDBTransactionEmbedding(embedding)
        try await dbQueue.write { db in
            try record.save(db)
        }
    }

    public func embedding(for transactionId: String) async throws -> StoredEmbedding? {
        try await dbQueue.read { db in
            try GRDBTransactionEmbedding
                .filter(Column("transactionId") == transactionId)
                .fetchOne(db)?
                .toDomain()
        }
    }

    public func allEmbeddings() async throws -> [StoredEmbedding] {
        try await dbQueue.read { db in
            try GRDBTransactionEmbedding.fetchAll(db).compactMap { $0.toDomain() }
        }
    }

    public func delete(transactionId: String) async throws {
        try await dbQueue.write { db in
            try GRDBTransactionEmbedding
                .filter(Column("transactionId") == transactionId)
                .deleteAll(db)
        }
    }

    public func count() async throws -> Int {
        try await dbQueue.read { db in
            try GRDBTransactionEmbedding.fetchCount(db)
        }
    }
}

// MARK: - GRDB Record

struct GRDBTransactionEmbedding: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "transaction_embeddings"

    let transactionId: String
    let label: String
    let embeddingBlob: Data
    let modelVersion: String
    let updatedAt: Date

    init(_ stored: StoredEmbedding) {
        transactionId = stored.transactionId
        label = stored.label
        embeddingBlob = stored.vector.withUnsafeBufferPointer { Data(buffer: $0) }
        modelVersion = stored.modelVersion
        updatedAt = stored.updatedAt
    }

    func toDomain() -> StoredEmbedding? {
        guard embeddingBlob.count % MemoryLayout<Float>.size == 0 else { return nil }
        let count = embeddingBlob.count / MemoryLayout<Float>.size
        let vector = embeddingBlob.withUnsafeBytes { ptr in
            Array(ptr.bindMemory(to: Float.self).prefix(count))
        }
        return StoredEmbedding(
            transactionId: transactionId, label: label,
            vector: vector, modelVersion: modelVersion, updatedAt: updatedAt
        )
    }
}

// MARK: - Migration helper

extension GRDBTransactionEmbedding {
    static func createTable(in database: Database) throws {
        guard try !database.tableExists(databaseTableName) else { return }
        try database.create(table: databaseTableName) { table in
            table.column("transactionId", .text).primaryKey()
            table.column("label", .text).notNull()
            table.column("embeddingBlob", .blob).notNull()
            table.column("modelVersion", .text).notNull()
            table.column("updatedAt", .datetime).notNull()
        }
        try database.create(index: "idx_txn_embeddings_label", on: databaseTableName, columns: ["label"])
        try database.create(index: "idx_txn_embeddings_updated", on: databaseTableName, columns: ["updatedAt"])
    }
}
