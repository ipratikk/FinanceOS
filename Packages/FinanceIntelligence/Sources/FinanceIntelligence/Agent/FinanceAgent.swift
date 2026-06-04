import FinanceCore
import Foundation

// MARK: - Finance Agent Query

public struct AgentQuery: Sendable {
    public let text: String
    public let parameters: [String: String]

    public init(text: String, parameters: [String: String] = [:]) {
        self.text = text
        self.parameters = parameters
    }
}

// MARK: - Finance Agent Response

public struct AgentResponse: Sendable {
    public let query: AgentQuery
    public let answer: String
    public let toolsUsed: [String]
    public let results: [AgentToolResult]

    public init(query: AgentQuery, answer: String, toolsUsed: [String], results: [AgentToolResult]) {
        self.query = query
        self.answer = answer
        self.toolsUsed = toolsUsed
        self.results = results
    }
}

// MARK: - FinanceAgent

/// Rule-based financial query agent with 7 structured tools.
///
/// Answers natural language queries about spending, income, and cashflow
/// by dispatching to the appropriate tool based on keyword matching.
/// Leverages Models 2, 3, 4, 6 outputs via pre-enriched transactions.
///
/// Tool dispatch:
///   spend_by_category — spend / spending / category / categorize
///   top_merchants     — merchant / store / shop / vendor / where
///   recurring_commitments — recurring / subscription / regular / commitment
///   income_sources    — income / salary / credit / earned / received
///   anomalies         — anomaly / unusual / suspicious / weird / large
///   cashflow_summary  — cashflow / cash flow / net / balance / summary
///   forecast_next_month — forecast / predict / next month / estimate / will spend
public struct FinanceAgent: Sendable {
    private let tools: [String: any FinanceAgentTool]

    public init() {
        let allTools: [any FinanceAgentTool] = [
            SpendByCategoryTool(),
            TopMerchantsTool(),
            RecurringCommitmentsTool(),
            IncomeSourcesTool(),
            AnomaliesDetectionTool(),
            CashflowSummaryTool(),
            ForecastNextMonthTool()
        ]
        tools = Dictionary(uniqueKeysWithValues: allTools.map { ($0.name, $0) })
    }

    /// Available tool names (all 7).
    public var toolNames: [String] {
        Array(tools.keys).sorted()
    }

    /// Answer a natural language query using the available tools.
    public func answer(query: AgentQuery, transactions: [Transaction]) -> AgentResponse {
        let toolName = selectTool(for: query.text)
        guard let tool = tools[toolName] else {
            return AgentResponse(
                query: query,
                answer: "I couldn't find the right tool. Try asking about spending, income, or cashflow.",
                toolsUsed: [],
                results: []
            )
        }
        let result = tool.call(transactions: transactions, parameters: query.parameters)
        return AgentResponse(
            query: query,
            answer: result.summary,
            toolsUsed: [toolName],
            results: [result]
        )
    }

    // MARK: - Tool Selection (keyword dispatch)

    func selectTool(for queryText: String) -> String {
        let lower = queryText.lowercased()

        if lower.contains("forecast") || lower.contains("predict") || lower.contains("next month")
            || lower.contains("estimate") || lower.contains("will spend") {
            return "forecast_next_month"
        }
        if lower.contains("cashflow") || lower.contains("cash flow") || lower.contains("net ")
            || lower.contains("summary") || lower.contains("balance") {
            return "cashflow_summary"
        }
        if lower.contains("anomal") || lower.contains("unusual") || lower.contains("suspicious")
            || lower.contains("weird") || lower.contains("large transaction") {
            return "anomalies"
        }
        if lower.contains("income") || lower.contains("salary") || lower.contains("earned")
            || lower.contains("received") || (lower.contains("credit") && !lower.contains("card")) {
            return "income_sources"
        }
        if lower.contains("recurring") || lower.contains("subscription") || lower.contains("regular")
            || lower.contains("commitment") || lower.contains("monthly payment") {
            return "recurring_commitments"
        }
        if lower.contains("merchant") || lower.contains("store") || lower.contains("shop")
            || lower.contains("vendor") || lower.contains("where do") || lower.contains("where did") {
            return "top_merchants"
        }
        // Default: category breakdown
        return "spend_by_category"
    }
}
