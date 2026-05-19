import Foundation
import GRDB

func grdbInsert(_ record: some PersistableRecord & Sendable, in queue: DatabaseQueue) async throws {
    try await queue.write { db in
        try record.insert(db)
    }
}

func grdbUpdate(_ record: some PersistableRecord & Sendable, in queue: DatabaseQueue) async throws {
    try await queue.write { db in
        try record.update(db)
    }
}

func grdbDelete<T: PersistableRecord & Identifiable & Sendable>(
    _ type: T.Type,
    key: UUID,
    in queue: DatabaseQueue
) async throws {
    try await queue.write { db in
        try T.deleteOne(db, key: key)
    }
}
