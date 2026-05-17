import FinanceCore
import SwiftUI

struct AdaptiveNavigation: View {
    @Environment(AppNavigator.self) private var navigator
    @Environment(\.horizontalSizeClass) var sizeClass
    private let appContainer = AppContainer.shared

    var body: some View {
        if sizeClass == .compact {
            iPhoneTabView
        } else {
            iPadSplitView
        }
    }

    var iPhoneTabView: some View {
        TabView(selection: .init(
            get: { navigator.sidebarSelection },
            set: { navigator.navigate(to: $0) }
        )) {
            DashboardView()
                .tabItem {
                    Label(NavigationItem.dashboard.label, systemImage: NavigationItem.dashboard.icon)
                }
                .tag(NavigationItem.dashboard)

            TransactionsView(
                viewModel: TransactionsViewModel(
                    transactionRepository: appContainer.transactionRepository,
                    ledgerRepository: appContainer.ledgerRepository
                )
            )
            .tabItem {
                Label(NavigationItem.transactions.label, systemImage: NavigationItem.transactions.icon)
            }
            .tag(NavigationItem.transactions)

            AccountsView(
                viewModel: AccountsViewModel(
                    ledgerRepository: appContainer.ledgerRepository,
                    bankRepository: appContainer.bankRepository,
                    transactionRepository: appContainer.transactionRepository
                ),
                transactionRepository: appContainer.transactionRepository,
                ledgerRepository: appContainer.ledgerRepository
            )
            .tabItem {
                Label(NavigationItem.accounts.label, systemImage: NavigationItem.accounts.icon)
            }
            .tag(NavigationItem.accounts)

            CardsView(
                viewModel: CardsViewModel(
                    ledgerRepository: appContainer.ledgerRepository,
                    bankRepository: appContainer.bankRepository,
                    transactionRepository: appContainer.transactionRepository
                ),
                transactionRepository: appContainer.transactionRepository,
                ledgerRepository: appContainer.ledgerRepository
            )
            .tabItem {
                Label(NavigationItem.cards.label, systemImage: NavigationItem.cards.icon)
            }
            .tag(NavigationItem.cards)

            BanksView(
                viewModel: BanksViewModel(
                    repository: appContainer.bankRepository
                )
            )
            .tabItem {
                Label(NavigationItem.banks.label, systemImage: NavigationItem.banks.icon)
            }
            .tag(NavigationItem.banks)
        }
    }

    var iPadSplitView: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SidebarView()
        } detail: {
            DetailRouter(appContainer: appContainer)
        }
    }
}

struct DetailRouter: View {
    @Environment(AppNavigator.self) private var navigator
    let appContainer: AppContainer

    var body: some View {
        NavigationStack(path: .init(
            get: { navigator.detailPath },
            set: { navigator.detailPath = $0 }
        )) {
            detailContent
                .navigationDestination(for: DetailDestination.self) { destination in
                    destinationView(for: destination)
                }
        }
    }

    @ViewBuilder
    var detailContent: some View {
        switch navigator.sidebarSelection {
        case .dashboard:
            DashboardView()
        case .transactions:
            TransactionsView(
                viewModel: TransactionsViewModel(
                    transactionRepository: appContainer.transactionRepository,
                    ledgerRepository: appContainer.ledgerRepository
                )
            )
        case .accounts:
            AccountsView(
                viewModel: AccountsViewModel(
                    ledgerRepository: appContainer.ledgerRepository,
                    bankRepository: appContainer.bankRepository,
                    transactionRepository: appContainer.transactionRepository
                ),
                transactionRepository: appContainer.transactionRepository,
                ledgerRepository: appContainer.ledgerRepository
            )
        case .cards:
            CardsView(
                viewModel: CardsViewModel(
                    ledgerRepository: appContainer.ledgerRepository,
                    bankRepository: appContainer.bankRepository,
                    transactionRepository: appContainer.transactionRepository
                ),
                transactionRepository: appContainer.transactionRepository,
                ledgerRepository: appContainer.ledgerRepository
            )
        case .banks:
            BanksView(
                viewModel: BanksViewModel(
                    repository: appContainer.bankRepository
                )
            )
        case .analytics:
            AnalyticsView()
        case .importStatement:
            ImportView(
                viewModel: ImportViewModel(
                    transactionImportPipeline: appContainer.transactionImportPipeline,
                    bankRepository: appContainer.bankRepository,
                    ledgerRepository: appContainer.ledgerRepository,
                    transactionRepository: appContainer.transactionRepository
                )
            )
        case .settings:
            SettingsView()
        }
    }

    @ViewBuilder
    func destinationView(for destination: DetailDestination) -> some View {
        switch destination {
        case let .accountTransactions(ledgerId):
            AccountTransactionsDestinationView(
                ledgerId: ledgerId,
                transactionRepository: appContainer.transactionRepository,
                ledgerRepository: appContainer.ledgerRepository
            )
        case let .cardTransactions(ledgerId):
            CardTransactionsDestinationView(
                ledgerId: ledgerId,
                transactionRepository: appContainer.transactionRepository,
                ledgerRepository: appContainer.ledgerRepository
            )
        }
    }
}

#Preview {
    let navigator = AppNavigator()
    return AdaptiveNavigation()
        .environment(navigator)
}
