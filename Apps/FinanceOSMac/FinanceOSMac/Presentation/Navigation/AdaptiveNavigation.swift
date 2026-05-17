import FinanceCore
import SwiftUI

struct AdaptiveNavigation: View {
    @Binding var selection: NavigationItem?
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
        NavigationStack {
            TabView(selection: $selection) {
                DashboardView(selection: $selection)
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
                    ledgerRepository: appContainer.ledgerRepository,
                    selection: selection
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
                    ledgerRepository: appContainer.ledgerRepository,
                    selection: selection
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
    }

    var iPadSplitView: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SidebarView(selection: $selection)
        } detail: {
            DetailRouter(selection: $selection, appContainer: appContainer)
        }
    }
}

struct DetailRouter: View {
    @Binding var selection: NavigationItem?
    let appContainer: AppContainer

    var body: some View {
        switch selection {
        case .dashboard:
            DashboardView(selection: $selection)
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
                ledgerRepository: appContainer.ledgerRepository,
                selection: selection
            )
        case .cards:
            CardsView(
                viewModel: CardsViewModel(
                    ledgerRepository: appContainer.ledgerRepository,
                    bankRepository: appContainer.bankRepository,
                    transactionRepository: appContainer.transactionRepository
                ),
                transactionRepository: appContainer.transactionRepository,
                ledgerRepository: appContainer.ledgerRepository,
                selection: selection
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
        case .none:
            DashboardView(selection: $selection)
        }
    }
}

#Preview {
    @Previewable @State var selection: NavigationItem? = .dashboard
    return AdaptiveNavigation(selection: $selection)
}
