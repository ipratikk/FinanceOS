import FinanceCore
import FinanceOSAPI
import FinanceUI
import Foundation

@Observable @MainActor
final class InsightNarrativeViewModel {
    struct InsightItem: Identifiable {
        var id: String {
            text
        }

        let text: String
        let severity: NarrativeSeverity
    }

    var insights: [InsightItem] = []
    var isLoading = false

    private let graphQLClient: ApolloGraphQLClient

    init(graphQLClient: ApolloGraphQLClient) {
        self.graphQLClient = graphQLClient
    }

    func refreshIfNeeded() async {
        await refresh()
    }

    func refresh() async {
        // Insights will be served by the backend — stub until GQL endpoint ships
        insights = []
    }
}
