import FinanceCore
import FinanceOSAPI
import FinanceParsers
import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class AccountsViewModel: AsyncLoadable, DeletableViewModel {
    private let graphQLClient: ApolloGraphQLClient
    private let logger = FinanceLogger.userInterface

    var accounts: [Ledger] = []
    var banks: [Bank] = []
    var balancesByAccount: [UUID: AccountLedgerBalance] = [:]
    var isLoading = false
    var deleteError: String?

    init(graphQLClient: ApolloGraphQLClient) {
        self.graphQLClient = graphQLClient
    }

    func loadAccounts() async {
        await withLoading(onError: { [self] error in
            logger.logError("Failed to load accounts: {error}", ["error": error.localizedDescription])
        }, {
            let data = try await graphQLClient.fetch(query: GetLedgersQuery())
            let bankData = try await graphQLClient.fetch(query: GetBanksQuery())
            let allLedgers = data.ledgers.map(GraphQLMappings.mapLedger)
            self.banks = bankData.banks.map(GraphQLMappings.mapBank)
            self.accounts = allLedgers.filter { $0.kind == .bankAccount }
            self.balancesByAccount = Dictionary(
                uniqueKeysWithValues: data.ledgers
                    .filter { $0.kind.value == .bankAccount }
                    .map { item in
                        let id = UUID(uuidString: item.id) ?? UUID()
                        let balance = AccountLedgerBalance(
                            netMinorUnits: Int64(item.balance * 100),
                            latestPostedAt: nil
                        )
                        return (id, balance)
                    }
            )
        })
    }

    func updateAccount(_ account: Ledger) async {
        do {
            let input = UpdateLedgerInput(
                displayName: .some(account.displayName),
                kind: .some(.init(account.kind == .creditCard ? FinanceOSAPI.LedgerKind.creditCard : .bankAccount)),
                last4: account.last4.isEmpty ? .null : .some(account.last4)
            )
            _ = try await graphQLClient.perform(mutation: UpdateLedgerMutation(id: account.id.uuidString, input: input))
            await loadAccounts()
        } catch {
            logger.logError(
                "Failed to update account: {error}",
                ["accountId": account.id.uuidString, "error": error.localizedDescription]
            )
        }
    }

    func deleteAccount(id: UUID) async {
        await performDelete({
            logger.logDebug("Deleting account", ["accountId": id.uuidString])
            _ = try await graphQLClient.perform(mutation: DeleteLedgerMutation(id: id.uuidString))
            logger.logInfo("Account deleted successfully", ["accountId": id.uuidString])
        }, onError: { [self] error in
            logger.logError(
                "Delete account failed: {error}",
                ["accountId": id.uuidString, "error": error.localizedDescription]
            )
        }, onSuccess: loadAccounts)
    }

    var groupedAccountsByBank: [(bankName: String, ledgers: [Ledger])] {
        let grouped = Dictionary(grouping: accounts) { ledger in
            banks.first { $0.id == ledger.bankId }?.name ?? "Unknown"
        }
        return grouped.map { (bankName: $0.key, ledgers: $0.value) }
            .sorted { $0.bankName < $1.bankName }
    }

    func statementSource(for ledger: Ledger) -> StatementSource? {
        let bank = banks.first { $0.id == ledger.bankId }
        guard let bankEnum = bank?.bank else { return nil }
        switch (bankEnum, ledger.kind) {
        case (.hdfc, .bankAccount): return .hdfcBank
        case (.hdfc, .creditCard): return .hdfcCard
        case (.icici, .bankAccount): return .iciciBank
        case (.icici, .creditCard): return .iciciCard
        case (.amex, _): return .amex
        default: return nil
        }
    }

    func convertToCard(_ account: Ledger) async {
        do {
            let input = UpdateLedgerInput(
                displayName: .some(account.displayName),
                kind: .some(.init(FinanceOSAPI.LedgerKind.creditCard)),
                last4: account.last4.isEmpty ? .null : .some(account.last4)
            )
            _ = try await graphQLClient.perform(mutation: UpdateLedgerMutation(id: account.id.uuidString, input: input))
            await loadAccounts()
        } catch {
            logger.logError(
                "Failed to convert account to card: {error}",
                ["accountId": account.id.uuidString, "error": error.localizedDescription]
            )
        }
    }
}
