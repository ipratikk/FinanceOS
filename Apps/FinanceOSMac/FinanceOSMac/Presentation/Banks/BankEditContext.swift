import FinanceCore
import FinanceOSAPI
import Foundation
import SwiftUI

@Observable
@MainActor
final class BankEditContext {
    private let graphQLClient: ApolloGraphQLClient
    var linkedLedgers: [Ledger] = []
    var error: String?

    init(graphQLClient: ApolloGraphQLClient) {
        self.graphQLClient = graphQLClient
    }

    func loadLedgers(bankId: UUID) async {
        do {
            let data = try await graphQLClient.fetch(query: GetLedgersQuery())
            linkedLedgers = data.ledgers
                .map(GraphQLMappings.mapLedger)
                .filter { $0.bankId == bankId }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateBank(_ bank: Bank) async {
        error = "Bank editing is not available in thin-client mode."
    }

    func deleteBank(id: UUID) async {
        error = "Bank deletion is not available in thin-client mode."
    }

    func clearError() {
        error = nil
    }
}
