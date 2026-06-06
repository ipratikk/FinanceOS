import Foundation

/// Typed request enum for all intelligence service operations.
/// All public consumers must use these types instead of calling methods directly.
public enum IntelligenceRequest: Sendable {
    case categorize(CategorizeRequest)
    case analyzeSpending(SpendingAnalysisRequest)
    case detectRecurring(RecurringDetectionRequest)
    case detectSalary(SalaryDetectionRequest)
    case analyzeCashflow(CashflowRequest)
    case resolveEntities(EntityResolutionRequest)
    case generateInsight(InsightRequest)
    case enrichTransaction(EnrichTransactionRequest)
}

public struct EnrichTransactionRequest: Sendable {
    /// Specific IDs to enrich. Nil = all transactions missing descriptions.
    public let transactionIDs: [UUID]?
    /// If true, regenerate even if description already set.
    public let forceReprocess: Bool

    public init(transactionIDs: [UUID]? = nil, forceReprocess: Bool = false) {
        self.transactionIDs = transactionIDs
        self.forceReprocess = forceReprocess
    }
}

public struct CategorizeRequest: Sendable {
    public let transactionIDs: [UUID]
    public let forceReprocess: Bool

    public init(transactionIDs: [UUID], forceReprocess: Bool = false) {
        self.transactionIDs = transactionIDs
        self.forceReprocess = forceReprocess
    }
}

public struct SpendingAnalysisRequest: Sendable {
    public let dateRange: DateInterval
    public let ledgerIDs: [UUID]?

    public init(dateRange: DateInterval, ledgerIDs: [UUID]? = nil) {
        self.dateRange = dateRange
        self.ledgerIDs = ledgerIDs
    }
}

public struct RecurringDetectionRequest: Sendable {
    public let transactionIDs: [UUID]?
    public let minimumOccurrences: Int

    public init(transactionIDs: [UUID]? = nil, minimumOccurrences: Int = 2) {
        self.transactionIDs = transactionIDs
        self.minimumOccurrences = minimumOccurrences
    }
}

public struct SalaryDetectionRequest: Sendable {
    public let ledgerIDs: [UUID]?

    public init(ledgerIDs: [UUID]? = nil) {
        self.ledgerIDs = ledgerIDs
    }
}

public struct CashflowRequest: Sendable {
    public let dateRange: DateInterval

    public init(dateRange: DateInterval) {
        self.dateRange = dateRange
    }
}

public struct EntityResolutionRequest: Sendable {
    public let transactionIDs: [UUID]?

    public init(transactionIDs: [UUID]? = nil) {
        self.transactionIDs = transactionIDs
    }
}

public struct InsightRequest: Sendable {
    public let context: InsightContext

    public enum InsightContext: Sendable {
        case spending(dateRange: DateInterval)
        case merchant(name: String)
        case category(name: String)
    }

    public init(context: InsightContext) {
        self.context = context
    }
}
