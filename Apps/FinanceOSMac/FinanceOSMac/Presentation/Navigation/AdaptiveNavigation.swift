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
                DashboardView()
                    .tabItem {
                        Label(NavigationItem.dashboard.label, systemImage: NavigationItem.dashboard.icon)
                    }
                    .tag(NavigationItem.dashboard)

                TransactionsView(
                    viewModel: TransactionsViewModel(
                        transactionRepository: appContainer.transactionRepository,
                        accountRepository: appContainer.accountRepository,
                        cardRepository: appContainer.cardRepository
                    )
                )
                .tabItem {
                    Label(NavigationItem.transactions.label, systemImage: NavigationItem.transactions.icon)
                }
                .tag(NavigationItem.transactions)

                AccountsView(
                    viewModel: AccountsViewModel(
                        repository: appContainer.accountRepository,
                        bankRepository: appContainer.bankRepository,
                        cardRepository: appContainer.cardRepository,
                        transactionRepository: appContainer.transactionRepository
                    ),
                    transactionRepository: appContainer.transactionRepository,
                    cardRepository: appContainer.cardRepository
                )
                .tabItem {
                    Label(NavigationItem.accounts.label, systemImage: NavigationItem.accounts.icon)
                }
                .tag(NavigationItem.accounts)

                CardsView(
                    viewModel: CardsViewModel(
                        cardRepository: appContainer.cardRepository,
                        accountRepository: appContainer.accountRepository,
                        bankRepository: appContainer.bankRepository,
                        transactionRepository: appContainer.transactionRepository
                    ),
                    transactionRepository: appContainer.transactionRepository,
                    accountRepository: appContainer.accountRepository
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
            DetailRouter(selection: selection, appContainer: appContainer)
        }
    }
}

struct DetailRouter: View {
    let selection: NavigationItem?
    let appContainer: AppContainer

    var body: some View {
        switch selection {
        case .dashboard:
            DashboardView()
        case .transactions:
            TransactionsView(
                viewModel: TransactionsViewModel(
                    transactionRepository: appContainer.transactionRepository,
                    accountRepository: appContainer.accountRepository,
                    cardRepository: appContainer.cardRepository
                )
            )
        case .accounts:
            AccountsView(
                viewModel: AccountsViewModel(
                    repository: appContainer.accountRepository,
                    bankRepository: appContainer.bankRepository,
                    cardRepository: appContainer.cardRepository,
                    transactionRepository: appContainer.transactionRepository
                ),
                transactionRepository: appContainer.transactionRepository,
                cardRepository: appContainer.cardRepository
            )
        case .cards:
            CardsView(
                viewModel: CardsViewModel(
                    cardRepository: appContainer.cardRepository,
                    accountRepository: appContainer.accountRepository,
                    bankRepository: appContainer.bankRepository,
                    transactionRepository: appContainer.transactionRepository
                ),
                transactionRepository: appContainer.transactionRepository,
                accountRepository: appContainer.accountRepository
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
                    accountRepository: appContainer.accountRepository,
                    cardRepository: appContainer.cardRepository,
                    transactionRepository: appContainer.transactionRepository
                )
            )
        case .none:
            DashboardView()
        }
    }
}

#Preview {
    @Previewable @State var selection: NavigationItem? = .dashboard
    return AdaptiveNavigation(selection: $selection)
}
