import Foundation

/// A single financial transaction produced by the Normalizer stage.
/// Amounts are stored as minor units (paise): positive = debit, negative = credit.
/// `sourceFingerprint` is a deterministic hash used for deduplication across imports.
public struct ParsedTransaction: Codable, Sendable, Equatable {
    /// Stable identifier; regenerated on each parse run, so equality uses `sourceFingerprint`.
    public let id: UUID
    /// Settlement date of the transaction in IST.
    public let postedAt: Date
    /// Raw description string as it appears on the bank statement.
    public let description: String
    /// Transaction amount in paise; positive = debit (money out), negative = credit (money in).
    public let amountMinorUnits: Int64
    /// ISO 4217 currency code, typically `"INR"`.
    public let currencyCode: String
    /// Deterministic hash of (date, description, amount) used to detect duplicate imports.
    public let sourceFingerprint: String
    /// Reward points earned, if reported by the bank (credit cards only).
    public let rewardPoints: Int64?
    /// Running account balance after this transaction, in paise, if provided.
    public let closingBalanceMinorUnits: Int64?

    public init(
        postedAt: Date,
        description: String,
        amountMinorUnits: Int64,
        currencyCode: String,
        sourceFingerprint: String,
        rewardPoints: Int64? = nil,
        closingBalanceMinorUnits: Int64? = nil
    ) {
        id = UUID()
        self.postedAt = postedAt
        self.description = description
        self.amountMinorUnits = amountMinorUnits
        self.currencyCode = currencyCode
        self.sourceFingerprint = sourceFingerprint
        self.rewardPoints = rewardPoints
        self.closingBalanceMinorUnits = closingBalanceMinorUnits
    }

    enum CodingKeys: String, CodingKey {
        case id, postedAt, description, amountMinorUnits, currencyCode, sourceFingerprint, rewardPoints
        case closingBalanceMinorUnits
    }

    /// Equality ignores `id` so that two parses of the same row compare equal.
    public static func == (lhs: ParsedTransaction, rhs: ParsedTransaction) -> Bool {
        lhs.postedAt == rhs.postedAt &&
            lhs.description == rhs.description &&
            lhs.amountMinorUnits == rhs.amountMinorUnits &&
            lhs.currencyCode == rhs.currencyCode &&
            lhs.sourceFingerprint == rhs.sourceFingerprint &&
            lhs.rewardPoints == rhs.rewardPoints &&
            lhs.closingBalanceMinorUnits == rhs.closingBalanceMinorUnits
    }
}
