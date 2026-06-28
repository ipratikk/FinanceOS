import FinanceCore
import FinanceOSAPI
import FinanceUI
import Foundation
import Observation

@Observable
@MainActor
final class LedgerDetailViewModel: AsyncLoadable {
    private let ledgerId: UUID
    private let graphQLClient: ApolloGraphQLClient

    private(set) var ledger: Ledger?
    private(set) var bank: Bank?
    var isLoading = false

    init(ledgerId: UUID, graphQLClient: ApolloGraphQLClient) {
        self.ledgerId = ledgerId
        self.graphQLClient = graphQLClient
    }

    func load() async {
        await withLoading {
            async let ledgersFetch = graphQLClient.fetch(query: GetLedgersQuery())
            async let banksFetch = graphQLClient.fetch(query: GetBanksQuery())
            let (ledgerData, bankData) = try await (ledgersFetch, banksFetch)
            let ledgers = ledgerData.ledgers.map(GraphQLMappings.mapLedger)
            let banks = bankData.banks.map(GraphQLMappings.mapBank)
            ledger = ledgers.first(where: { $0.id == ledgerId })
            bank = banks.first { $0.id == ledger?.bankId }
        }
    }

    var balanceText: String {
        FormatterCache.formatCurrency(minorUnits: ledger?.closingBalance ?? 0)
    }

    var navigationTitle: String {
        ledger?.displayName ?? "Ledger"
    }
}
