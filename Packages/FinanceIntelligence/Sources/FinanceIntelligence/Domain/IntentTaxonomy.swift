import Foundation

/// A transaction's financial intent — the *why* behind a payment, distinct from its category.
///
/// Category answers "what kind of spending?"; intent answers "what was the user actually doing?".
/// Example: AmEx payment → category: `fees`, intent: `creditCardPayment`.
public enum TransactionIntent: String, Codable, Sendable, CaseIterable {
    case salary             = "salary"
    case rent               = "rent"
    case investment         = "investment"
    case mutualFundSIP      = "mutual_fund_sip"
    case insurance          = "insurance"
    case subscription       = "subscription"
    case creditCardPayment  = "credit_card_payment"
    case loanPayment        = "loan_payment"
    case cashWithdrawal     = "cash_withdrawal"
    case refund             = "refund"
    case cashback           = "cashback"
    case transfer           = "transfer"
    case interestPayment    = "interest_payment"
    case utilityBill        = "utility_bill"
    case shopping           = "shopping"
    case groceries          = "groceries"
    case food               = "food"
    case travel             = "travel"
    case healthcare         = "healthcare"
    case income             = "income"
    case unknown            = "unknown"

    public var displayName: String {
        switch self {
        case .salary: return "Salary"
        case .rent: return "Rent"
        case .investment: return "Investment"
        case .mutualFundSIP: return "Mutual Fund SIP"
        case .insurance: return "Insurance"
        case .subscription: return "Subscription"
        case .creditCardPayment: return "Credit Card Payment"
        case .loanPayment: return "Loan Payment"
        case .cashWithdrawal: return "Cash Withdrawal"
        case .refund: return "Refund"
        case .cashback: return "Cashback"
        case .transfer: return "Transfer"
        case .interestPayment: return "Interest Payment"
        case .utilityBill: return "Utility Bill"
        case .shopping: return "Shopping"
        case .groceries: return "Groceries"
        case .food: return "Food & Dining"
        case .travel: return "Travel"
        case .healthcare: return "Healthcare"
        case .income: return "Income"
        case .unknown: return "Unknown"
        }
    }
}

/// How an `IntentPrediction` was determined.
public enum IntentPredictionSource: String, Codable, Sendable {
    case ruleEngine     = "rule_engine"
    case userCorrection = "user_correction"
    case fallback       = "fallback"
}

/// The intent classification produced by the intelligence pipeline for a transaction.
public struct IntentPrediction: Sendable, Codable {
    public let intent: TransactionIntent
    /// Confidence in [0, 1]. Values below 0.5 indicate low certainty.
    public let confidence: Double
    public let source: IntentPredictionSource

    public init(intent: TransactionIntent, confidence: Double, source: IntentPredictionSource) {
        self.intent = intent
        self.confidence = max(0, min(1, confidence))
        self.source = source
    }

    /// A low-confidence placeholder used when no rule matched.
    public static let unknown = IntentPrediction(
        intent: .unknown,
        confidence: 0.3,
        source: .fallback
    )
}
