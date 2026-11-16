import Foundation
import GRDB

/// Represents a linked pair of transactions forming a single transfer event.
/// Used for inter-account transfers, credit card payments, and other paired flows.
public struct TransferEvent:
    Identifiable,
    Codable,
    Sendable,
    FetchableRecord,
    PersistableRecord,
    Equatable {
    public let id: UUID
    /// First transaction id (typically debit/source side).
    public let transactionId1: String
    /// Second transaction id (typically credit/destination side).
    public let transactionId2: String
    /// Transfer event type (e.g., "internal_transfer", "credit_card_payment", "loan_transfer").
    public let eventType: String
    /// Optional notes describing the transfer.
    public let notes: String?
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        transactionId1: String,
        transactionId2: String,
        eventType: String,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.transactionId1 = transactionId1
        self.transactionId2 = transactionId2
        self.eventType = eventType
        self.notes = notes
        self.createdAt = createdAt
    }
}
