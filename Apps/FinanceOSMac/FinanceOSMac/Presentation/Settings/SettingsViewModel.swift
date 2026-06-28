import FinanceCore
import FinanceOSAPI
import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    private let graphQLClient: ApolloGraphQLClient

    var errorMessage: String?

    init(graphQLClient: ApolloGraphQLClient) {
        self.graphQLClient = graphQLClient
    }

    func clearAllData() async {
        do {
            _ = try await graphQLClient.perform(mutation: ClearAllDataMutation())
            try DatabaseManager.shared.clearIntelligenceData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
