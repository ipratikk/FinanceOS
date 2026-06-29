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
            DashboardView(
                viewModel: DashboardViewModel(
                    graphQLClient: appContainer.graphQLClient,
                    exportService: ExportService()
                ),
                insightsViewModel: InsightNarrativeViewModel(
                    graphQLClient: appContainer.graphQLClient
                )
            )
            .tabItem {
                Label(NavigationItem.dashboard.label, systemImage: NavigationItem.dashboard.icon)
            }
            .tag(NavigationItem.dashboard)

            TransactionsView(
                viewModel: TransactionsViewModel(
                    graphQLClient: appContainer.graphQLClient
                ),
                graphQLClient: appContainer.graphQLClient
            )
            .tabItem {
                Label(NavigationItem.transactions.label, systemImage: NavigationItem.transactions.icon)
            }
            .tag(NavigationItem.transactions)

            AccountsView(
                viewModel: AccountsViewModel(
                    graphQLClient: appContainer.graphQLClient
                )
            )
            .tabItem {
                Label(NavigationItem.accounts.label, systemImage: NavigationItem.accounts.icon)
            }
            .tag(NavigationItem.accounts)

            CardsView(
                viewModel: CardsViewModel(
                    graphQLClient: appContainer.graphQLClient
                )
            )
            .tabItem {
                Label(NavigationItem.cards.label, systemImage: NavigationItem.cards.icon)
            }
            .tag(NavigationItem.cards)

            BanksView(
                viewModel: BanksViewModel(
                    graphQLClient: appContainer.graphQLClient
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
            DashboardView(
                viewModel: DashboardViewModel(
                    graphQLClient: appContainer.graphQLClient,
                    exportService: ExportService()
                ),
                insightsViewModel: InsightNarrativeViewModel(
                    graphQLClient: appContainer.graphQLClient
                )
            )
        case .transactions:
            TransactionsView(
                viewModel: TransactionsViewModel(
                    graphQLClient: appContainer.graphQLClient
                ),
                graphQLClient: appContainer.graphQLClient
            )
        case .accounts:
            AccountsView(
                viewModel: AccountsViewModel(
                    graphQLClient: appContainer.graphQLClient
                )
            )
        case .cards:
            CardsView(
                viewModel: CardsViewModel(
                    graphQLClient: appContainer.graphQLClient
                )
            )
        case .banks:
            BanksView(
                viewModel: BanksViewModel(
                    graphQLClient: appContainer.graphQLClient
                )
            )
        case .analytics:
            AnalyticsView(viewModel: AnalyticsViewModel(
                graphQLClient: appContainer.graphQLClient,
                aggregator: AnalyticsAggregatorService()
            ))
        case .importStatement:
            ImportView(
                viewModel: ImportViewModel(
                    graphQLClient: appContainer.graphQLClient,
                    initialTarget: navigator.pendingImportTarget
                )
            )
        case .settings:
            SettingsView(viewModel: SettingsViewModel(graphQLClient: appContainer.graphQLClient))
        }
    }

    @ViewBuilder
    func destinationView(for destination: DetailDestination) -> some View {
        switch destination {
        case let .accountTransactions(ledgerId):
            AccountTransactionsDestinationView(
                ledgerId: ledgerId,
                graphQLClient: appContainer.graphQLClient
            )
        case let .cardTransactions(ledgerId):
            CardTransactionsDestinationView(
                ledgerId: ledgerId,
                graphQLClient: appContainer.graphQLClient
            )
        case let .ledgerDetail(ledgerId):
            LedgerDetailDestinationView(
                ledgerId: ledgerId,
                graphQLClient: appContainer.graphQLClient
            )
        }
    }
}

#Preview {
    let navigator = AppNavigator()
    return AdaptiveNavigation()
        .environment(navigator)
}
