import Foundation
import GRDB

func grdbInsert(_ record: some PersistableRecord & Sendable, in queue: DatabaseQueue) async throws {
    try await queue.write { database in
        try record.insert(database)
    }
}

func grdbUpdate(_ record: some PersistableRecord & Sendable, in queue: DatabaseQueue) async throws {
    try await queue.write { database in
        try record.update(database)
    }
}

func grdbDelete<T: PersistableRecord & Identifiable & Sendable>(
    _ type: T.Type,
    key: UUID,
    in queue: DatabaseQueue
) async throws {
    try await queue.write { database in
        _ = try T.deleteOne(database, key: key)
    }
}
