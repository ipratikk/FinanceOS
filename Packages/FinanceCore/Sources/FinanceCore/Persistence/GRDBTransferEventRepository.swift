import Foundation
import GRDB

/// GRDB-backed TransferEventRepository implementation.
actor GRDBTransferEventRepository: TransferEventRepository {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func fetchTransferEventsFor(transactionId: UUID) async throws -> [TransferEvent] {
        try await dbQueue.read { db in
            let txnId = transactionId.uuidString
            return try TransferEvent
                .filter(sql: "transactionId1 = ? OR transactionId2 = ?", arguments: [txnId, txnId])
                .fetchAll(db)
        }
    }

    func createTransferEvent(_ event: TransferEvent) async throws {
        try await dbQueue.write { db in
            try event.insert(db)
        }
    }

    func fetchTransferEvent(id: UUID) async throws -> TransferEvent? {
        try await dbQueue.read { db in
            try TransferEvent.fetchOne(db, key: id)
        }
    }

    func deleteTransferEvent(id: UUID) async throws {
        try await dbQueue.write { db in
            _ = try TransferEvent.deleteOne(db, key: id)
        }
    }
}
