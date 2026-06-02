---
doc: 023-agent-architecture
version: 0.1.0
status: Draft
date: 2026-06-02
---

# Agent Architecture — FinanceAgent

## Purpose

Define the complete architecture for `FinanceAgent`: the on-device financial AI assistant that answers natural language questions about the user's finances using tool calls to query the GRDB database. The agent never accesses the database directly — all data access happens through typed Swift tools that the LLM orchestrates.

---

## Design Principles

1. **Tool-mediated data access.** The LLM reasons and plans; tools fetch data. LLM never writes SQL.
2. **Grounded responses only.** Every factual claim in an agent response must come from a tool call result. LLM cannot invent financial figures.
3. **Local first.** All inference runs on-device via `MLXLLMProvider`. No cloud API calls.
4. **Deterministic tool execution.** Tools are pure functions over the database. Same query → same result.
5. **Context budget awareness.** Agent manages conversation context to stay within LLM context window.
6. **No financial advice.** Agent reports facts, patterns, and summaries. It does not recommend investments, insurance, or financial products.

---

## Architecture Overview

```
User query (natural language)
          │
          ▼
[FinanceAgent.respond(query)]
          │
          ▼
[ContextManager.buildContext(query, history, financialData)]
  → system prompt + conversation history + financial context
          │
          ▼
[MLXLLMProvider.completeWithTools(messages, tools, options)]
  → LLM generates either: (a) tool call, or (b) final response
          │
    ┌─────┴──────┐
    ▼            ▼
[Tool Call]   [Final Response]
    │               │
    ▼               ▼
[ToolCallingEngine.execute(toolCall)]   [AgentResponseParser.parse(response)]
    │                                        │
    ▼                                        ▼
[Repository Query via tool]            [AgentResponse]
    │
    ▼
[Tool Result → back to LLM]
  (loop until final response or max iterations)
```

---

## Tool Definitions

### Tool Protocol

```swift
// Agent/Tools/AgentTool.swift

public protocol AgentTool: Sendable {
    var name: String { get }
    var description: String { get }
    var parameters: [ToolParameter] { get }
    
    func execute(_ arguments: [String: Any]) async throws -> ToolResult
}

public struct ToolParameter: Sendable {
    public let name: String
    public let type: ParameterType
    public let description: String
    public let required: Bool
    public let enumValues: [String]?
}

public struct ToolResult: Sendable {
    public let success: Bool
    public let data: Any?
    public let error: String?
    public let tokenCount: Int   // approximate tokens when serialized
}
```

---

### QueryTransactionsTool

```swift
public final class QueryTransactionsTool: AgentTool {
    public let name = "query_transactions"
    public let description = """
        Query the user's transactions with filters.
        Returns matching transactions with merchant, category, amount, and date.
        Use this to answer questions about spending, income, or specific payments.
        """
    
    public let parameters: [ToolParameter] = [
        ToolParameter(name: "start_date", type: .string,
                      description: "Start date in YYYY-MM-DD format", required: false),
        ToolParameter(name: "end_date", type: .string,
                      description: "End date in YYYY-MM-DD format", required: false),
        ToolParameter(name: "category", type: .string,
                      description: "Filter by category name", required: false,
                      enumValues: TransactionCategory.allCases.map { $0.rawValue }),
        ToolParameter(name: "merchant", type: .string,
                      description: "Filter by merchant name (partial match)", required: false),
        ToolParameter(name: "direction", type: .string,
                      description: "credit or debit", required: false,
                      enumValues: ["credit", "debit"]),
        ToolParameter(name: "min_amount", type: .number,
                      description: "Minimum transaction amount", required: false),
        ToolParameter(name: "max_amount", type: .number,
                      description: "Maximum transaction amount", required: false),
        ToolParameter(name: "limit", type: .integer,
                      description: "Maximum results (default: 20, max: 100)", required: false),
    ]
    
    public func execute(_ arguments: [String: Any]) async throws -> ToolResult {
        let query = TransactionQuery.from(arguments)
        let results = try await transactionRepository.query(query)
        return ToolResult(
            success: true,
            data: results.map { TransactionSummary(from: $0) },
            error: nil,
            tokenCount: results.count * 40  // approximate
        )
    }
}
```

---

### QueryBudgetsTool

```swift
public final class QueryBudgetsTool: AgentTool {
    public let name = "query_budgets"
    public let description = """
        Get budget vs. actual spending comparison for a period.
        Returns category-level budget, actual spend, and remaining.
        """
    
    public let parameters: [ToolParameter] = [
        ToolParameter(name: "month", type: .string,
                      description: "Month in YYYY-MM format", required: true),
    ]
    
    public func execute(_ arguments: [String: Any]) async throws -> ToolResult {
        guard let month = arguments["month"] as? String else {
            return ToolResult(success: false, data: nil, error: "month is required")
        }
        let comparison = try await budgetRepository.comparison(for: month)
        return ToolResult(success: true, data: comparison, error: nil, tokenCount: 200)
    }
}
```

---

### QueryAccountsTool

```swift
public final class QueryAccountsTool: AgentTool {
    public let name = "query_accounts"
    public let description = """
        Get account balances and recent summary.
        Returns account names, types, last known balance.
        """
    // Minimal parameters (no date filter — always returns current state)
}
```

---

### QueryCategoriesTool

```swift
public final class QueryCategoriesTool: AgentTool {
    public let name = "query_category_totals"
    public let description = """
        Get spending totals grouped by category for a period.
        Use this for "how much did I spend on X this month" questions.
        """
    
    public let parameters: [ToolParameter] = [
        ToolParameter(name: "start_date", type: .string, description: "Start date (YYYY-MM-DD)", required: true),
        ToolParameter(name: "end_date", type: .string, description: "End date (YYYY-MM-DD)", required: true),
        ToolParameter(name: "direction", type: .string, description: "credit or debit", required: false),
    ]
}
```

---

### QueryMerchantsTool

```swift
public final class QueryMerchantsTool: AgentTool {
    public let name = "query_merchant_totals"
    public let description = """
        Get spending totals grouped by merchant for a period.
        Use for "top merchants" or "how much at X" questions.
        """
}
```

---

### QueryRecurringTool

```swift
public final class QueryRecurringTool: AgentTool {
    public let name = "query_recurring"
    public let description = """
        Get detected recurring transactions (subscriptions, bills, SIPs).
        Returns merchant, cadence, amount, next expected date.
        """
}
```

---

## System Prompt

```swift
let FINANCE_AGENT_SYSTEM_PROMPT = """
You are FinanceOS, a personal finance assistant. You help users understand their spending, \
income, and financial patterns by analyzing their transaction data.

CRITICAL RULES:
1. NEVER invent financial figures. Only state numbers that come from tool results.
2. Always use tools to fetch data before answering factual questions.
3. Do NOT provide investment advice, tax advice, or financial recommendations.
4. Use ₹ for Indian Rupee amounts.
5. When uncertain about dates, ask the user to clarify rather than assuming.
6. If data is not available, say so clearly.

TOOL USAGE:
- For spending questions: use query_category_totals or query_transactions
- For merchant questions: use query_merchant_totals or query_transactions
- For balance questions: use query_accounts
- For recurring/subscription questions: use query_recurring
- For budget questions: use query_budgets

Today's date: \(Date.formatted(.iso8601))
"""
```

---

## FinanceAgent Implementation

```swift
// Agent/FinanceAgent.swift

public final class FinanceAgent {
    private let llmProvider: any LLMProvider
    private let toolEngine: ToolCallingEngine
    private let contextManager: ContextManager
    private let memory: ConversationMemory
    private let maxToolIterations = 5

    public func respond(to query: String) async throws -> AgentResponse {
        let context = await contextManager.buildContext(query: query, history: await memory.messages)
        
        var messages = await memory.messages + [LLMMessage(role: .user, content: query)]
        var iterations = 0

        while iterations < maxToolIterations {
            let result = try await llmProvider.completeWithTools(
                messages: messages,
                tools: toolEngine.allTools.map { $0.asLLMTool() },
                options: agentOptions
            )

            switch result {
            case .toolCall(let call):
                let toolResult = try await toolEngine.execute(call)
                let toolMessage = LLMMessage(role: .tool, content: toolResult.serialized,
                                            toolCallID: call.id)
                messages.append(contentsOf: [
                    LLMMessage(role: .assistant, content: nil, toolCalls: [call]),
                    toolMessage
                ])
                iterations += 1

            case .finalResponse(let text):
                let response = AgentResponseParser.parse(text)
                await memory.append(LLMMessage(role: .assistant, content: text))
                return response
            }
        }

        throw AgentError.maxIterationsExceeded
    }
}
```

---

## ToolCallingEngine

```swift
// Agent/ToolCallingEngine.swift

public final class ToolCallingEngine {
    private let tools: [String: any AgentTool]
    
    public var allTools: [any AgentTool] { Array(tools.values) }

    public init(repositories: RepositoryContainer) {
        tools = [
            "query_transactions":   QueryTransactionsTool(repo: repositories.transactions),
            "query_budgets":        QueryBudgetsTool(repo: repositories.budgets),
            "query_accounts":       QueryAccountsTool(repo: repositories.accounts),
            "query_category_totals": QueryCategoriesTool(repo: repositories.transactions),
            "query_merchant_totals": QueryMerchantsTool(repo: repositories.transactions),
            "query_recurring":      QueryRecurringTool(repo: repositories.recurring),
        ]
    }

    public func execute(_ call: LLMToolCall) async throws -> ToolResult {
        guard let tool = tools[call.name] else {
            throw ToolError.unknownTool(call.name)
        }
        return try await tool.execute(call.arguments)
    }
}
```

---

## Query Examples

```
User: "How much did I spend on food last month?"
Agent: [calls query_category_totals(start_date="2026-05-01", end_date="2026-05-31", direction="debit")]
       [tool result: {food: 3420, dining: 4890}]
Agent: "You spent ₹3,420 on food and ₹4,890 on dining in May 2026, totalling ₹8,310."

User: "What's my biggest recurring expense?"
Agent: [calls query_recurring()]
       [tool result: [{merchant: "Rent", amount: 25000, cadence: monthly}, ...]]
Agent: "Your largest recurring expense is your rent at ₹25,000/month, followed by..."

User: "Did I pay my HDFC credit card bill this month?"
Agent: [calls query_transactions(category="creditCardPayment", start_date="2026-06-01", end_date="2026-06-30")]
       [tool result: [{merchant: "HDFC Bank", amount: 12500, date: "2026-06-05"}]]
Agent: "Yes, you paid ₹12,500 to HDFC credit card on June 5, 2026."
```

---

## Performance Targets

| Metric | Target |
|---|---|
| Agent response latency (simple, 1 tool call) | < 5 s on iPhone 15 Pro |
| Agent response latency (complex, 3 tool calls) | < 12 s on iPhone 15 Pro |
| Tool execution latency | < 200 ms per tool call |
| Max tool iterations | 5 (prevents runaway loops) |
| Context window budget | 4,096 tokens (Phi-3 Mini) / 8,192 tokens (Qwen3 4B) |

---

## Risks

| Risk | Mitigation |
|---|---|
| LLM hallucinates financial amounts not in tool results | System prompt rule + output validation: check all amounts against tool results |
| Tool call loop (LLM keeps calling tools without final response) | Max iterations cap (5); graceful error message to user |
| User asks for investment/tax advice | System prompt refusal rule; agent responds "I cannot provide financial advice" |
| Tool query too broad (100,000 transactions returned) | Enforce `limit` parameter; default limit = 20; max = 100 |
| Conversation memory grows past context window | `ConversationMemory` trims oldest turns; always preserves system prompt |
