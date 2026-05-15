import SwiftUI

struct AdaptiveNavigation: View {
    @Binding var selection: NavigationItem?
    @Environment(\.horizontalSizeClass) var sizeClass

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

                TransactionsView()
                    .tabItem {
                        Label(NavigationItem.transactions.label, systemImage: NavigationItem.transactions.icon)
                    }
                    .tag(NavigationItem.transactions)

                AccountsView()
                    .tabItem {
                        Label(NavigationItem.accounts.label, systemImage: NavigationItem.accounts.icon)
                    }
                    .tag(NavigationItem.accounts)

                CardsView()
                    .tabItem {
                        Label(NavigationItem.cards.label, systemImage: NavigationItem.cards.icon)
                    }
                    .tag(NavigationItem.cards)

                BanksView()
                    .tabItem {
                        Label(NavigationItem.banks.label, systemImage: NavigationItem.banks.icon)
                    }
                    .tag(NavigationItem.banks)
            }
        }
    }

    var iPadSplitView: some View {
        NavigationSplitView(columnVisibility: .all) {
            SidebarView(selection: $selection)
        } detail: {
            DetailRouter(selection: selection)
        }
    }
}

struct DetailRouter: View {
    let selection: NavigationItem?

    var body: some View {
        switch selection {
        case .dashboard:
            DashboardView()
        case .transactions:
            TransactionsView()
        case .accounts:
            AccountsView()
        case .cards:
            CardsView()
        case .banks:
            BanksView()
        case .analytics:
            AnalyticsView()
        case .importStatement:
            ImportView()
        case .none:
            DashboardView()
        }
    }
}

#Preview {
    @State var selection: NavigationItem? = .dashboard
    return AdaptiveNavigation(selection: $selection)
}
