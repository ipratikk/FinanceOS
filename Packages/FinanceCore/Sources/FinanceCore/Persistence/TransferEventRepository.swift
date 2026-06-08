import Foundation

/// Repository for transfer event persistence.
public protocol TransferEventRepository: Sendable {
    /// Fetch all transfer events for a transaction ID (as either side of the pair).
    func fetchTransferEventsFor(transactionId: UUID) async throws -> [TransferEvent]
    /// Create new transfer event linking two transactions.
    func createTransferEvent(_ event: TransferEvent) async throws
    /// Fetch transfer event by ID.
    func fetchTransferEvent(id: UUID) async throws -> TransferEvent?
    /// Delete transfer event by ID.
    func deleteTransferEvent(id: UUID) async throws
}
