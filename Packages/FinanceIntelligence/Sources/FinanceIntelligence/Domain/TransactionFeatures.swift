import Foundation

/// Feature vector extracted from a Transaction. Only created by TransactionFeatureExtractor.
public struct TransactionFeatures: Sendable {
    public let rawDescription: String
    public let normalizedDescription: String
    public let tokens: [String]
    public let amountMinorUnits: Int64
    public let absoluteAmountMinorUnits: Int64
    public let isDebit: Bool
    public let currencyCode: String
    public let dayOfWeek: Int
    public let dayOfMonth: Int
    public let month: Int
    public let isWeekend: Bool
    public let hasOnlineIndicator: Bool
    public let hasRecurringIndicator: Bool
    public let hasTransferIndicator: Bool
    public let hasPayrollIndicator: Bool
    public let hasRefundIndicator: Bool
    public let institutionHint: String?
    public let ledgerKindHint: String?
}
