import Foundation

/// Feature vector extracted from a `Transaction` by `TransactionFeatureExtractor`.
/// Only created by that extractor — do not construct directly.
public struct TransactionFeatures: Sendable {
    /// Unmodified description from the bank statement.
    public let rawDescription: String
    /// Lowercased, cleaned description used for ML inference and rule matching.
    public let normalizedDescription: String
    /// Whitespace/punctuation-split tokens from `normalizedDescription` (length >= 2).
    public let tokens: [String]
    /// Transaction amount in the smallest currency unit (paise for INR, cents for USD). Negative for debits.
    public let amountMinorUnits: Int64
    /// Absolute value of `amountMinorUnits` — always non-negative.
    public let absoluteAmountMinorUnits: Int64
    /// True when `transactionType == .debit`.
    public let isDebit: Bool
    /// ISO 4217 currency code (e.g. `"INR"`, `"USD"`).
    public let currencyCode: String
    /// Gregorian day-of-week (1 = Sunday … 7 = Saturday).
    public let dayOfWeek: Int
    /// Gregorian day-of-month (1–31).
    public let dayOfMonth: Int
    /// Gregorian month (1–12).
    public let month: Int
    /// True when `dayOfWeek` is Saturday (7) or Sunday (1).
    public let isWeekend: Bool
    /// True when the description contains online/digital-commerce indicators.
    public let hasOnlineIndicator: Bool
    /// True when the description contains subscription, EMI, or recurring-payment keywords.
    public let hasRecurringIndicator: Bool
    /// True when the description looks like a P2P or bank transfer (UPI, NEFT, IMPS, RTGS).
    public let hasTransferIndicator: Bool
    /// True when the description contains salary or payroll keywords.
    public let hasPayrollIndicator: Bool
    /// True when the description contains refund or reversal keywords.
    public let hasRefundIndicator: Bool
    /// True when the description indicates a credit card bill payment (BBPS, CRED, AEBC VPA, "payment received").
    public let hasCreditCardPaymentIndicator: Bool
    /// Bank or institution name supplied by the ledger context (e.g. `"HDFC"`, `"ICICI"`).
    public let institutionHint: String?
    /// Raw value of `LedgerKind` for the source ledger (e.g. `"savings"`, `"credit"`).
    public let ledgerKindHint: String?
}
