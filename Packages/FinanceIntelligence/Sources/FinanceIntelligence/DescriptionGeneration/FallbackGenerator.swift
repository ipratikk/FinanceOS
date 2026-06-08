import Foundation

/// Deterministic, truthful description generator. Never invents data.
///
/// Standardization policy: the canonical merchant/person name IS the description.
/// The category, intent, and direction are surfaced elsewhere in the UI — the
/// description never restates them with invented activity ("grocery order",
/// "shopping spree"). Only the merchant-less ATM case adds words beyond the name.
///
/// Structured opaque bank formats (remittance, GST, interest, salary, rent)
/// are handled upstream by `RawPatternParser` before this generator runs — that is
/// where rent/salary labels come from, derived from explicit keywords in the raw string.
public struct FallbackGenerator: Sendable {
    public init() {}

    /// Generate a human-readable description from structured context.
    /// Always returns a non-empty string. Every word derives from verified data.
    public func generate(from context: DescriptionContext) -> String {
        // ATM withdrawals carry no useful counterparty name.
        if context.intent == .cashWithdrawal { return "ATM Cash Withdrawal" }

        // Default: the canonical merchant/person name is the description.
        let name = context.merchantName.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty { return name }
        return context.isDebit ? "Debit transaction" : "Credit transaction"
    }
}
