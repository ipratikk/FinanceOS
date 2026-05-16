import Foundation

public struct ParsedTransaction: Codable, Sendable, Equatable {
    public let id: UUID
    public let postedAt: Date
    public let description: String
    public let amountMinorUnits: Int64
    public let currencyCode: String
    public let sourceFingerprint: String
    public let rewardPoints: Int64?

    public init(
        postedAt: Date,
        description: String,
        amountMinorUnits: Int64,
        currencyCode: String,
        sourceFingerprint: String,
        rewardPoints: Int64? = nil
    ) {
        id = UUID()
        self.postedAt = postedAt
        self.description = description
        self.amountMinorUnits = amountMinorUnits
        self.currencyCode = currencyCode
        self.sourceFingerprint = sourceFingerprint
        self.rewardPoints = rewardPoints
    }

    enum CodingKeys: String, CodingKey {
        case id, postedAt, description, amountMinorUnits, currencyCode, sourceFingerprint, rewardPoints
    }

    public static func == (lhs: ParsedTransaction, rhs: ParsedTransaction) -> Bool {
        lhs.postedAt == rhs.postedAt &&
        lhs.description == rhs.description &&
        lhs.amountMinorUnits == rhs.amountMinorUnits &&
        lhs.currencyCode == rhs.currencyCode &&
        lhs.sourceFingerprint == rhs.sourceFingerprint &&
        lhs.rewardPoints == rhs.rewardPoints
    }
}
