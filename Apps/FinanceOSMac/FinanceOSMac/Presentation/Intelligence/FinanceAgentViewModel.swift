import FinanceCore
import FinanceIntelligence
import FinanceOSAPI
import Foundation

@Observable @MainActor
final class FinanceAgentViewModel {
    struct QueryEntry: Identifiable {
        let id: UUID
        let query: String
        let answer: String
        let toolUsed: String
    }

    var queryText: String = ""
    var history: [QueryEntry] = []
    var isLoading: Bool = false
    var error: String?

    private let agent = FinanceAgent()
    private let graphQLClient: ApolloGraphQLClient
    private var cachedTransactions: [Transaction] = []
    private var isLoadingTransactions = false

    init(graphQLClient: ApolloGraphQLClient) {
        self.graphQLClient = graphQLClient
    }

    func loadTransactions() async {
        guard cachedTransactions.isEmpty, !isLoadingTransactions else { return }
        isLoadingTransactions = true
        defer { isLoadingTransactions = false }
        do {
            let data = try await graphQLClient.fetch(
                query: GetTransactionsQuery(ledgerId: .none, filter: .none, limit: .none)
            )
            cachedTransactions = data.transactions.map(GraphQLMappings.mapTransaction)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func submit() async {
        let text = queryText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        queryText = ""
        await submitQuery(text)
    }

    func submitQuery(_ text: String) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        await loadTransactions()
        let query = AgentQuery(text: text)
        let agentCapture = agent
        let txCapture = cachedTransactions
        let response = await Task.detached(priority: .userInitiated) {
            agentCapture.answer(query: query, transactions: txCapture)
        }.value
        let entry = QueryEntry(
            id: UUID(),
            query: text,
            answer: response.answer,
            toolUsed: response.toolsUsed.first ?? "unknown"
        )
        history.append(entry)
    }
}
