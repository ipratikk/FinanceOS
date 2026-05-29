import Foundation
import GRDB

/// Inserts a single GRDB record in a serialised write transaction.
/// Internal helper used by GRDB repository implementations to reduce boilerplate.
func grdbInsert(_ record: some PersistableRecord & Sendable, in queue: DatabaseQueue) async throws {
    try await queue.write { database in
        try record.insert(database)
    }
}

/// Updates a single GRDB record in a serialised write transaction.
func grdbUpdate(_ record: some PersistableRecord & Sendable, in queue: DatabaseQueue) async throws {
    try await queue.write { database in
        try record.update(database)
    }
}

/// Deletes a single GRDB record by UUID primary key; silently succeeds if the row is absent.
func grdbDelete<T: PersistableRecord & Identifiable & Sendable>(
    _ type: T.Type,
    key: UUID,
    in queue: DatabaseQueue
) async throws {
    try await queue.write { database in
        _ = try T.deleteOne(database, key: key)
    }
}
