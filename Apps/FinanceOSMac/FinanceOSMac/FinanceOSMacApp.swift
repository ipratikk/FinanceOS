import FinanceCore
import SwiftUI

@main
struct FinanceOSMacApp: App {
    private let appContainer = AppContainer.shared
    @State private var isCheckingDependencies = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                TabView {
                    ImportView(
                        viewModel: ImportViewModel(
                            transactionImporter: appContainer.transactionImporter,
                            transactionImportPipeline: appContainer.transactionImportPipeline,
                            institutionRepository: appContainer.institutionRepository,
                            accountRepository: appContainer.accountRepository,
                            cardRepository: appContainer.cardRepository,
                            parserRegistry: appContainer.parserRegistry
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
                .disabled(isCheckingDependencies)
                .opacity(isCheckingDependencies ? 0.5 : 1)

                if isCheckingDependencies {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)

                        VStack(spacing: 4) {
                            Text("Setting up")
                                .font(.headline)

                            Text("Installing dependencies...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                    .shadow(radius: 4)
                }
            }
            .task {
                defer { isCheckingDependencies = false }
                await DependencyChecker.ensureSSConvertAvailable()
            }
        }
    }
}
