import Foundation

enum NavigationItem: Hashable, CaseIterable {
    case dashboard
    case transactions
    case accounts
    case cards
    case banks
    case analytics
    case importStatement

    var label: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .transactions: return "Transactions"
        case .accounts: return "Accounts"
        case .cards: return "Cards"
        case .banks: return "Banks"
        case .analytics: return "Analytics"
        case .importStatement: return "Import"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .transactions: return "list.bullet"
        case .accounts: return "building.2"
        case .cards: return "creditcard"
        case .banks: return "building.columns"
        case .analytics: return "chart.bar"
        case .importStatement: return "arrow.down.doc"
        }
    }
}
