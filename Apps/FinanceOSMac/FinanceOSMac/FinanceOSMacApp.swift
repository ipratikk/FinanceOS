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
                        transactionImportPipeline: appContainer.transactionImportPipeline,
                        bankRepository: appContainer.bankRepository,
                        accountRepository: appContainer.accountRepository,
                        cardRepository: appContainer.cardRepository,
                        transactionRepository: appContainer.transactionRepository,
                        parserRegistry: appContainer.parserRegistry
                    )
                )
                .tabItem {
                    Label("Import", systemImage: "arrow.down.doc")
                }

                BanksView(
                    viewModel: BanksViewModel(
                        repository: appContainer.bankRepository
                    )
                )
                .tabItem {
                    Label("Banks", systemImage: "building.columns")
                }

                AccountsView(
                    viewModel: AccountsViewModel(
                        repository: appContainer.accountRepository,
                        bankRepository: appContainer.bankRepository,
                        cardRepository: appContainer.cardRepository,
                        transactionRepository: appContainer.transactionRepository
                    )
                )
                .tabItem {
                    Label("Accounts", systemImage: "building.columns.circle")
                }

                CardsView(
                    viewModel: CardsViewModel(
                        cardRepository: appContainer.cardRepository,
                        accountRepository: appContainer.accountRepository,
                        bankRepository: appContainer.bankRepository,
                        transactionRepository: appContainer.transactionRepository
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
