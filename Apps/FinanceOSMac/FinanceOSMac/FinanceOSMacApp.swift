import FinanceCore
import SwiftUI

@main
struct FinanceOSMacApp: App {
    private let appContainer = AppContainer.shared

    var body: some Scene {
        WindowGroup {
            TabView {
                ImportView(
                    viewModel: ImportViewModel(
                        transactionImporter: appContainer.transactionImporter,
                        transactionRepository: appContainer.transactionRepository,
                        accountRepository: appContainer.accountRepository,
                        cardRepository: appContainer.cardRepository
                    )
                )
                .tabItem {
                    Label("Import", systemImage: "arrow.down.doc")
                }

                InstitutionsView(
                    viewModel: InstitutionsViewModel(
                        repository: appContainer.institutionRepository
                    )
                )
                .tabItem {
                    Label("Institutions", systemImage: "building.columns")
                }

                AccountsView(
                    viewModel: AccountsViewModel(
                        repository: appContainer.accountRepository
                    )
                )
                .tabItem {
                    Label("Accounts", systemImage: "building.columns.circle")
                }

                CardsView(
                    viewModel: CardsViewModel(
                        cardRepository: appContainer.cardRepository,
                        accountRepository: appContainer.accountRepository,
                        institutionRepository: appContainer.institutionRepository
                    )
                )
                .tabItem {
                    Label("Cards", systemImage: "creditcard")
                }

                TransactionsView(
                    viewModel: TransactionsViewModel(
                        transactionRepository: appContainer.transactionRepository,
                        accountRepository: appContainer.accountRepository,
                        cardRepository: appContainer.cardRepository
                    )
                )
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle")
                }
            }
        }
    }
}
