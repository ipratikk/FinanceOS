//
//  BanksViewModel.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 15/05/26.
//

import FinanceCore
import FinanceOSAPI
import Foundation
import Observation

@MainActor
@Observable
final class BanksViewModel: AsyncLoadable {
    private let graphQLClient: ApolloGraphQLClient

    var banks: [Bank] = []
    var ledgersByBank: [UUID: [Ledger]] = [:]
    var isLoading = false

    init(graphQLClient: ApolloGraphQLClient) {
        self.graphQLClient = graphQLClient
    }

    func loadBanks() async {
        await withLoading(onError: { error in
            FinanceLogger.userInterface.logError("Failed to load banks", caughtError: error, [:])
        }, {
            async let banksFetch = graphQLClient.fetch(query: GetBanksQuery())
            async let ledgersFetch = graphQLClient.fetch(query: GetLedgersQuery())
            let (bankData, ledgerData) = try await (banksFetch, ledgersFetch)
            banks = bankData.banks.map(GraphQLMappings.mapBank)
            let ledgers = ledgerData.ledgers.map(GraphQLMappings.mapLedger)
            ledgersByBank = Dictionary(grouping: ledgers, by: { $0.bankId })
        })
    }
}
