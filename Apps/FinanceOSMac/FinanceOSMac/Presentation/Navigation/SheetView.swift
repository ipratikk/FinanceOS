import FinanceCore
import SwiftUI

struct SheetView: View {
    let route: SheetRoute
    let appContainer: AppContainer
    @State private var banks: [Bank] = []
    @State private var accounts: [Ledger] = []
    @Environment(\.cardReloadCallback) var cardReloadCallback

    var body: some View {
        Group {
            switch route {
            case let .accountEdit(ledger):
                let context = AccountEditContext(repository: appContainer.ledgerRepository, banks: banks)
                AccountEditView(account: ledger, context: context)
            case let .cardEdit(ledger):
                let context = CardEditContext(
                    repository: appContainer.ledgerRepository,
                    banks: banks,
                    accounts: accounts,
                    onUpdate: cardReloadCallback
                )
                CardEditView(card: ledger, context: context)
            case let .bankEdit(bank):
                let context = BankEditContext(repository: appContainer.bankRepository)
                BankEditView(bank: bank, context: context)
            default:
                EmptyView()
            }
        }
        .task {
            do {
                async let banksFetch = appContainer.bankRepository.fetchBanks()
                async let accountsFetch = appContainer.ledgerRepository.fetchLedgers(kind: .bankAccount)
                banks = try await banksFetch
                accounts = try await accountsFetch
            } catch {
                print("Failed to fetch data: \(error)")
            }
        }
    }
}
