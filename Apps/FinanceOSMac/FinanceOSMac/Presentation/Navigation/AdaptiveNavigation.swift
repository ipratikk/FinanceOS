import FinanceCore
import FinanceIntelligence
import SwiftUI

struct AdaptiveNavigation: View {
    @Environment(AppNavigator.self) private var navigator
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.transactionIntelligence) private var intelligence
    @Environment(\.categorizationScheduler) private var categorizationScheduler
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
                    spendingService: appContainer.spendingService,
                    transactionRepository: appContainer.transactionRepository,
                    ledgerRepository: appContainer.ledgerRepository,
                    exportService: ExportService()
                ),
                insightsViewModel: InsightNarrativeViewModel(
                    transactionRepository: appContainer.transactionRepository
                )
            )
            .tabItem {
                Label(NavigationItem.dashboard.label, systemImage: NavigationItem.dashboard.icon)
            }
            .tag(NavigationItem.dashboard)

            TransactionsView(
                viewModel: TransactionsViewModel(
                    transactionRepository: appContainer.transactionRepository,
                    ledgerRepository: appContainer.ledgerRepository,
                    intelligenceService: intelligence
                )
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
                    repository: appContainer.bankRepository,
                    ledgerRepository: appContainer.ledgerRepository
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
    @Environment(\.transactionIntelligence) private var intelligence
    @Environment(\.categorizationScheduler) private var categorizationScheduler
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
                    spendingService: appContainer.spendingService,
                    transactionRepository: appContainer.transactionRepository,
                    ledgerRepository: appContainer.ledgerRepository,
                    exportService: ExportService()
                ),
                insightsViewModel: InsightNarrativeViewModel(
                    transactionRepository: appContainer.transactionRepository
                )
            )
        case .transactions:
            TransactionsView(
                viewModel: TransactionsViewModel(
                    transactionRepository: appContainer.transactionRepository,
                    ledgerRepository: appContainer.ledgerRepository,
                    intelligenceService: intelligence
                )
            )
            .id(intelligence != nil)
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
                    repository: appContainer.bankRepository,
                    ledgerRepository: appContainer.ledgerRepository
                )
            )
        case .analytics:
            AnalyticsView(viewModel: AnalyticsViewModel(
                spendingService: appContainer.spendingService,
                transactionRepository: appContainer.transactionRepository,
                intelligenceService: intelligence,
                aggregator: AnalyticsAggregatorService()
            ))
        case .importStatement:
            ImportView(
                viewModel: ImportViewModel(
                    transactionImportPipeline: appContainer.transactionImportPipeline,
                    bankRepository: appContainer.bankRepository,
                    ledgerRepository: appContainer.ledgerRepository,
                    transactionRepository: appContainer.transactionRepository,
                    initialTarget: navigator.pendingImportTarget,
                    categorizationScheduler: categorizationScheduler
                )
            )
        case .settings:
            SettingsView(viewModel: SettingsViewModel(bankRepository: appContainer.bankRepository))
        case .intelligence:
            IntelligenceHubView(container: IntelligenceContainer.shared)
        case .financeAgent:
            FinanceAgentView(viewModel: FinanceAgentViewModel(
                transactionRepository: appContainer.transactionRepository
            ))
        }
    }

    @ViewBuilder
    func destinationView(for destination: DetailDestination) -> some View {
        switch destination {
        case let .accountTransactions(ledgerId):
            AccountTransactionsDestinationView(
                ledgerId: ledgerId,
                transactionRepository: appContainer.transactionRepository,
                ledgerRepository: appContainer.ledgerRepository,
                bankRepository: appContainer.bankRepository
            )
        case let .cardTransactions(ledgerId):
            CardTransactionsDestinationView(
                ledgerId: ledgerId,
                transactionRepository: appContainer.transactionRepository,
                ledgerRepository: appContainer.ledgerRepository
            )
        case let .ledgerDetail(ledgerId):
            LedgerDetailDestinationView(ledgerId: ledgerId)
        }
    }
}

#Preview {
    let navigator = AppNavigator()
    return AdaptiveNavigation()
        .environment(navigator)
}
