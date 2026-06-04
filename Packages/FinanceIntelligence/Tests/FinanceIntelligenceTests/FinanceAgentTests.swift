import FinanceCore
@testable import FinanceIntelligence
import Foundation
import Testing

@Suite("FinanceAgent — 7 tools, query dispatch")
struct FinanceAgentTests {
    let agent = FinanceAgent()

    private func makeTxn(
        amount: Int64, merchant: String = "Swiggy",
        category: String = "food", type: TransactionType = .debit
    ) -> Transaction {
        Transaction(
            postedAt: Date(), description: merchant,
            amountMinorUnits: amount, currencyCode: "INR",
            transactionType: type, categoryId: category, merchantName: merchant
        )
    }

    private var sampleTransactions: [Transaction] {
        [
            makeTxn(amount: 30000, merchant: "Swiggy", category: "food"),
            makeTxn(amount: 15000, merchant: "Swiggy", category: "food"),
            makeTxn(amount: 50000, merchant: "Uber", category: "travel"),
            makeTxn(amount: 100_000, merchant: "Employer", category: "income", type: .credit),
            makeTxn(amount: 20000, merchant: "Netflix", category: "entertainment"),
            makeTxn(amount: 20000, merchant: "Netflix", category: "entertainment"),
            makeTxn(amount: 20000, merchant: "Netflix", category: "entertainment")
        ]
    }

    @Test("Agent has exactly 7 tools")
    func toolCount() {
        #expect(agent.toolNames.count == 7)
    }

    @Test("All 7 tool names are present")
    func allToolNamesPresent() {
        let expected = Set([
            "spend_by_category", "top_merchants", "recurring_commitments",
            "income_sources", "anomalies", "cashflow_summary", "forecast_next_month"
        ])
        #expect(Set(agent.toolNames) == expected)
    }

    @Test("Spend query dispatches to spend_by_category")
    func spendQueryDispatch() {
        #expect(agent.selectTool(for: "What did I spend on food?") == "spend_by_category")
    }

    @Test("Merchant query dispatches to top_merchants")
    func merchantQueryDispatch() {
        #expect(agent.selectTool(for: "Which stores did I shop at?") == "top_merchants")
    }

    @Test("Recurring query dispatches correctly")
    func recurringQueryDispatch() {
        #expect(agent.selectTool(for: "Show my recurring subscriptions") == "recurring_commitments")
    }

    @Test("Income query dispatches correctly")
    func incomeQueryDispatch() {
        #expect(agent.selectTool(for: "How much salary did I receive?") == "income_sources")
    }

    @Test("Anomaly query dispatches correctly")
    func anomalyQueryDispatch() {
        #expect(agent.selectTool(for: "Any unusual transactions?") == "anomalies")
    }

    @Test("Cashflow query dispatches correctly")
    func cashflowQueryDispatch() {
        #expect(agent.selectTool(for: "What is my net cashflow?") == "cashflow_summary")
    }

    @Test("Forecast query dispatches correctly")
    func forecastQueryDispatch() {
        #expect(agent.selectTool(for: "Forecast next month spending") == "forecast_next_month")
    }

    @Test("Spend by category returns category names")
    func spendByCategoryResult() {
        let response = agent.answer(query: AgentQuery(text: "spending"), transactions: sampleTransactions)
        #expect(!response.answer.isEmpty)
        #expect(response.toolsUsed.contains("spend_by_category"))
    }

    @Test("Recurring tool detects Netflix pattern")
    func recurringDetectsPattern() {
        let tool = RecurringCommitmentsTool()
        let result = tool.call(transactions: sampleTransactions, parameters: [:])
        #expect(result.summary.contains("Netflix"))
    }

    @Test("Cashflow includes income and expenses")
    func cashflowSummaryResult() {
        let tool = CashflowSummaryTool()
        let result = tool.call(transactions: sampleTransactions, parameters: [:])
        #expect(result.summary.contains("Income"))
        #expect(result.summary.contains("Expenses"))
    }

    @Test("Income tool captures credit transactions")
    func incomeTool() {
        let tool = IncomeSourcesTool()
        let result = tool.call(transactions: sampleTransactions, parameters: [:])
        #expect(result.summary.contains("1000"))
    }

    @Test("Unknown query falls back to spend_by_category")
    func unknownQueryFallback() {
        #expect(agent.selectTool(for: "hello world random query") == "spend_by_category")
    }

    @Test("All 7 queries return non-empty answers")
    func allToolsReturnResponse() {
        let queries = [
            "spending by category", "top merchants", "recurring subscriptions",
            "income sources", "unusual transactions", "cashflow summary", "forecast next month"
        ]
        for queryText in queries {
            let response = agent.answer(query: AgentQuery(text: queryText), transactions: sampleTransactions)
            #expect(!response.answer.isEmpty, "Tool returned empty answer for: \(queryText)")
        }
    }
}
