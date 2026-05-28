import FinanceCore
import Foundation

public struct FeatureExtractionContext: Sendable {
    public let ledgerKind: LedgerKind?
    public let institution: String?

    public static let empty = FeatureExtractionContext(ledgerKind: nil, institution: nil)

    public init(ledgerKind: LedgerKind?, institution: String?) {
        self.ledgerKind = ledgerKind
        self.institution = institution
    }
}

/// Builds a TransactionFeatures vector from a Transaction.
public struct TransactionFeatureExtractor: Sendable {
    private static let calendar = Calendar(identifier: .gregorian)
    private let cleaner = MerchantTextCleaner()

    public init() {}

    public func extract(
        from transaction: Transaction,
        context: FeatureExtractionContext = .empty
    ) -> TransactionFeatures {
        let raw = transaction.description
        let normalized = cleaner.normalizedForMatching(raw)
        let tokens = tokenize(normalized)
        let comps = Self.calendar.dateComponents([.weekday, .day, .month], from: transaction.postedAt)
        let weekday = comps.weekday ?? 1
        let isWeekend = weekday == 1 || weekday == 7
        let isDebit = transaction.transactionType == .debit
        let amount = transaction.amountMinorUnits
        return TransactionFeatures(
            rawDescription: raw,
            normalizedDescription: normalized,
            tokens: tokens,
            amountMinorUnits: amount,
            absoluteAmountMinorUnits: abs(amount),
            isDebit: isDebit,
            currencyCode: transaction.currencyCode,
            dayOfWeek: weekday,
            dayOfMonth: comps.day ?? 1,
            month: comps.month ?? 1,
            isWeekend: isWeekend,
            hasOnlineIndicator: hasOnlineIndicator(normalized),
            hasRecurringIndicator: hasRecurringIndicator(normalized),
            hasTransferIndicator: hasTransferIndicator(raw: raw, normalized: normalized),
            hasPayrollIndicator: hasPayrollIndicator(normalized),
            hasRefundIndicator: hasRefundIndicator(normalized),
            institutionHint: context.institution,
            ledgerKindHint: context.ledgerKind?.rawValue
        )
    }
}

// MARK: - Private Helpers

private extension TransactionFeatureExtractor {
    func tokenize(_ normalized: String) -> [String] {
        normalized
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 2 }
    }

    func hasOnlineIndicator(_ normalized: String) -> Bool {
        let indicators = ["online", ".com", "http", "www", "digital", "app"]
        return indicators.contains { normalized.contains($0) }
    }

    func hasRecurringIndicator(_ normalized: String) -> Bool {
        let indicators = ["subscription", "recurring", "monthly", "annual", "autopay", "auto pay", "emi"]
        return indicators.contains { normalized.contains($0) }
    }

    // raw: original bank description (needed for UPI parser — cleaning strips the phone number in VPA)
    func hasTransferIndicator(raw: String, normalized: String) -> Bool {
        let hardTransferKeywords = ["transfer", "rtgs", "wire transfer", "zelle", "venmo"]
        if hardTransferKeywords.contains(where: { normalized.contains($0) }) { return true }
        // ACH debits (SIPs, EMIs, insurance) are recurring financial obligations, not P2P transfers
        // NEFT/IMPS: treat as transfer — UPI parser uses raw to preserve VPA phone numbers
        if normalized.hasPrefix("neft") || normalized.hasPrefix("imps") { return true }
        return UPIDescriptionParser.isLikelyTransfer(raw)
    }

    func hasPayrollIndicator(_ normalized: String) -> Bool {
        let indicators = ["salary", "payroll", "paycheck", "wages", "direct deposit", "stipend"]
        return indicators.contains { normalized.contains($0) }
    }

    func hasRefundIndicator(_ normalized: String) -> Bool {
        let indicators = ["refund", "reversal", "cashback", "chargeback", "credit back"]
        return indicators.contains { normalized.contains($0) }
    }
}
