import FinanceCore
import Foundation

// MARK: - Agent Tool Protocol

/// A callable tool available to `FinanceAgent` for answering financial queries.
public protocol FinanceAgentTool: Sendable {
    var name: String { get }
    var description: String { get }
    func call(transactions: [Transaction], parameters: [String: String]) -> AgentToolResult
}

// MARK: - Tool Result

public struct AgentToolResult: Sendable {
    public let toolName: String
    public let summary: String
    public let data: [String: String]

    public init(toolName: String, summary: String, data: [String: String] = [:]) {
        self.toolName = toolName
        self.summary = summary
        self.data = data
    }
}

// MARK: - Tool 1: Spend by Category

public struct SpendByCategoryTool: FinanceAgentTool {
    public let name = "spend_by_category"
    public let description = "Total spending grouped by category for a time range"
    public init() {}

    public func call(transactions: [Transaction], parameters: [String: String]) -> AgentToolResult {
        var totals: [String: Int64] = [:]
        for txn in transactions where txn.transactionType == .debit {
            let cat = txn.categoryId ?? "uncategorized"
            totals[cat, default: 0] += txn.amountMinorUnits
        }
        let sorted = totals.sorted { $0.value > $1.value }
        let summary = sorted.prefix(5).map { "\($0.key): ₹\($0.value / 100)" }.joined(separator: ", ")
        return AgentToolResult(
            toolName: name,
            summary: summary.isEmpty ? "No spending data" : summary,
            data: totals.mapValues { String($0 / 100) }
        )
    }
}

// MARK: - Tool 2: Top Merchants

public struct TopMerchantsTool: FinanceAgentTool {
    public let name = "top_merchants"
    public let description = "Top merchants by spending volume"
    public init() {}

    public func call(transactions: [Transaction], parameters: [String: String]) -> AgentToolResult {
        var totals: [String: Int64] = [:]
        for txn in transactions where txn.transactionType == .debit {
            let merchant = txn.merchantName ?? "Unknown"
            totals[merchant, default: 0] += txn.amountMinorUnits
        }
        let topN = Int(parameters["limit"] ?? "5") ?? 5
        let sorted = totals.sorted { $0.value > $1.value }.prefix(topN)
        let summary = sorted.map { "\($0.key): ₹\($0.value / 100)" }.joined(separator: ", ")
        return AgentToolResult(
            toolName: name,
            summary: summary.isEmpty ? "No merchant data" : summary,
            data: Dictionary(uniqueKeysWithValues: sorted.map { ($0.key, String($0.value / 100)) })
        )
    }
}

// MARK: - Tool 3: Recurring Commitments

public struct RecurringCommitmentsTool: FinanceAgentTool {
    public let name = "recurring_commitments"
    public let description = "Identify likely recurring payments from transaction history"
    public init() {}

    public func call(transactions: [Transaction], parameters: [String: String]) -> AgentToolResult {
        var merchantCounts: [String: Int] = [:]
        for txn in transactions where txn.transactionType == .debit {
            let merchant = txn.merchantName ?? "Unknown"
            merchantCounts[merchant, default: 0] += 1
        }
        let recurring = merchantCounts.filter { $0.value >= 2 }.sorted { $0.value > $1.value }
        let summary = recurring.prefix(5).map { "\($0.key) (\($0.value)x)" }.joined(separator: ", ")
        return AgentToolResult(
            toolName: name,
            summary: summary.isEmpty ? "No recurring patterns" : summary,
            data: recurring.prefix(10).reduce(into: [:]) { $0[$1.key] = String($1.value) }
        )
    }
}

// MARK: - Tool 4: Income Sources

public struct IncomeSourcesTool: FinanceAgentTool {
    public let name = "income_sources"
    public let description = "Income transactions grouped by source"
    public init() {}

    public func call(transactions: [Transaction], parameters: [String: String]) -> AgentToolResult {
        var totals: [String: Int64] = [:]
        for txn in transactions where txn.transactionType == .credit {
            let source = txn.merchantName ?? txn.categoryId ?? "income"
            totals[source, default: 0] += txn.amountMinorUnits
        }
        let total = totals.values.reduce(0, +)
        let summary = "Total income: ₹\(total / 100) from \(totals.count) source(s)"
        return AgentToolResult(
            toolName: name,
            summary: summary,
            data: totals.mapValues { String($0 / 100) }
        )
    }
}

// MARK: - Tool 5: Anomalies

public struct AnomaliesDetectionTool: FinanceAgentTool {
    public let name = "anomalies"
    public let description = "Detect unusually large transactions vs recent baseline"
    public init() {}

    public func call(transactions: [Transaction], parameters: [String: String]) -> AgentToolResult {
        let amounts = transactions.filter { $0.transactionType == .debit }.map { Double($0.amountMinorUnits) }
        guard amounts.count >= 5 else {
            return AgentToolResult(toolName: name, summary: "Insufficient data for anomaly detection")
        }
        let mean = amounts.reduce(0, +) / Double(amounts.count)
        let variance = amounts.map { pow($0 - mean, 2) }.reduce(0, +) / Double(amounts.count)
        let stdDev = sqrt(variance)
        let threshold = mean + 3 * stdDev
        let anomalyCount = amounts.count(where: { $0 > threshold })
        let summary = anomalyCount == 0
            ? "No anomalies detected"
            : "\(anomalyCount) anomalous transaction(s) found"
        return AgentToolResult(
            toolName: name,
            summary: summary,
            data: ["count": String(anomalyCount), "threshold": String(Int(threshold / 100))]
        )
    }
}

// MARK: - Tool 6: Cashflow Summary

public struct CashflowSummaryTool: FinanceAgentTool {
    public let name = "cashflow_summary"
    public let description = "Net cashflow (income minus expenses) for the period"
    public init() {}

    public func call(transactions: [Transaction], parameters: [String: String]) -> AgentToolResult {
        let income = transactions.filter { $0.transactionType == .credit }
            .map(\.amountMinorUnits).reduce(0, +)
        let expenses = transactions.filter { $0.transactionType == .debit }
            .map(\.amountMinorUnits).reduce(0, +)
        let net = income - expenses
        let direction = net >= 0 ? "surplus" : "deficit"
        let summary = "Income: ₹\(income / 100), Expenses: ₹\(expenses / 100), Net \(direction): ₹\(abs(net) / 100)"
        return AgentToolResult(
            toolName: name,
            summary: summary,
            data: ["income": String(income / 100), "expenses": String(expenses / 100), "net": String(net / 100)]
        )
    }
}

// MARK: - Tool 7: Forecast Next Month

public struct ForecastNextMonthTool: FinanceAgentTool {
    public let name = "forecast_next_month"
    public let description = "Estimate next month spend based on recent average"
    public init() {}

    public func call(transactions: [Transaction], parameters: [String: String]) -> AgentToolResult {
        let debits = transactions.filter { $0.transactionType == .debit }
        guard !debits.isEmpty else {
            return AgentToolResult(toolName: name, summary: "Insufficient data for forecast")
        }
        let totalMinorUnits = debits.map(\.amountMinorUnits).reduce(0, +)
        let dailyAvg = totalMinorUnits / max(1, Int64(debits.count))
        let monthlyEstimate = dailyAvg * 30
        let summary = "Estimated next month spending: ₹\(monthlyEstimate / 100) (based on daily average)"
        return AgentToolResult(
            toolName: name,
            summary: summary,
            data: ["forecast_minor_units": String(monthlyEstimate)]
        )
    }
}
