import FinanceCore
import FinanceOSAPI
import Foundation
import Observation

@Observable
@MainActor
final class CardTransactionsDestinationViewModel: AsyncLoadable {
    private let ledgerId: UUID
    private let graphQLClient: ApolloGraphQLClient

    private(set) var ledger: Ledger?
    var isLoading = false

    init(ledgerId: UUID, graphQLClient: ApolloGraphQLClient) {
        self.ledgerId = ledgerId
        self.graphQLClient = graphQLClient
    }

    func load() async {
        await withLoading {
            let data = try await graphQLClient.fetch(query: GetLedgersQuery())
            ledger = data.ledgers
                .map(GraphQLMappings.mapLedger)
                .first(where: { $0.id == ledgerId })
        }
    }
}
