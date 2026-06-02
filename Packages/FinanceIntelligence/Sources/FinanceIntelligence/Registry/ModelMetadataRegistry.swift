import FinanceCore
import Foundation
import GRDB

/// Persists model training metadata to `intelligence_model_metadata` table.
/// Tracks training runs, metrics, and versions.
///
/// - One row per training run — never overwrites existing rows.
/// - In debug builds, training without registering triggers `assertionFailure`.
/// - When no `DatabaseQueue` is available, registry operations are no-ops.
public final class ModelMetadataRegistry: Sendable {
    private let dbQueue: DatabaseQueue?

    public init(dbQueue: DatabaseQueue?) {
        self.dbQueue = dbQueue
    }

    /// Inserts metadata for a completed training run.
    public func register(_ entry: ModelMetadataEntry) async {
        guard let dbQueue else { return }
        do {
            let grdbEntry = GRDBModelMetadataEntry(entry: entry)
            try await dbQueue.write { db in try grdbEntry.insert(db) }
        } catch {
            FinanceLogger.intelligence.error("ModelMetadataRegistry register failed: \(error)")
        }
    }

    /// Returns most recent entry for `modelName`, or nil if none exists.
    public func currentVersion(for modelName: String) async -> ModelMetadataEntry? {
        guard let dbQueue else { return nil }
        do {
            return try await dbQueue.read { db in
                try GRDBModelMetadataEntry
                    .filter(Column("modelName") == modelName)
                    .order(Column("trainedAt").desc)
                    .fetchOne(db)
            }?.asEntry
        } catch {
            FinanceLogger.intelligence.error("ModelMetadataRegistry currentVersion failed: \(error)")
            return nil
        }
    }

    /// Returns up to `limit` entries for `modelName`, newest first.
    public func history(for modelName: String, limit: Int = 10) async -> [ModelMetadataEntry] {
        guard let dbQueue else { return [] }
        do {
            return try await dbQueue.read { db in
                try GRDBModelMetadataEntry
                    .filter(Column("modelName") == modelName)
                    .order(Column("trainedAt").desc)
                    .limit(limit)
                    .fetchAll(db)
            }.map(\.asEntry)
        } catch {
            FinanceLogger.intelligence.error("ModelMetadataRegistry history failed: \(error)")
            return []
        }
    }
}
