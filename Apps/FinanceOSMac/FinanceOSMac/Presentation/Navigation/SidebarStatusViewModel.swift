import FinanceCore
import FinanceOSAPI
import Foundation
import Observation

/// Sidebar footer status: whether the backend answers, and how many transactions it holds.
@Observable
@MainActor
final class SidebarStatusViewModel {
    enum State: Equatable {
        case checking
        case healthy(transactionCount: Int)
        case unreachable
    }

    private let graphQLClient: ApolloGraphQLClient
    private(set) var state: State = .checking

    init(graphQLClient: ApolloGraphQLClient) {
        self.graphQLClient = graphQLClient
    }

    func refresh() async {
        do {
            // networkOnly: the count must reflect the live database, not a cached list.
            let data = try await graphQLClient.fetch(
                query: GetTransactionsQuery(ledgerId: .none, filter: .none, limit: .none),
                cachePolicy: .networkOnly
            )
            state = .healthy(transactionCount: data.transactions.count)
        } catch {
            state = .unreachable
        }
    }
}
