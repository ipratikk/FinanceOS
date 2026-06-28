import FinanceCore
import FinanceOSAPI
import Foundation
import Observation

@Observable
@MainActor
final class SheetViewModel: AsyncLoadable {
    private let graphQLClient: ApolloGraphQLClient

    private(set) var banks: [Bank] = []
    private(set) var accounts: [Ledger] = []
    var isLoading = false

    init(graphQLClient: ApolloGraphQLClient) {
        self.graphQLClient = graphQLClient
    }

    func load() async {
        await withLoading {
            async let banksFetch = graphQLClient.fetch(query: GetBanksQuery())
            async let ledgersFetch = graphQLClient.fetch(query: GetLedgersQuery())
            let (bankData, ledgerData) = try await (banksFetch, ledgersFetch)
            banks = bankData.banks.map(GraphQLMappings.mapBank)
            accounts = ledgerData.ledgers.map(GraphQLMappings.mapLedger).filter { $0.kind == .bankAccount }
        }
    }
}
