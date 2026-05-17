import SwiftUI

/// Centralized navigation coordinator for the entire FinanceOS app.
/// All navigation state lives here: sidebar selection, detail push path, and modal sheets.
/// Injected via @Environment to avoid prop drilling.
@Observable
@MainActor
final class AppNavigator {
    var sidebarSelection: NavigationItem = .dashboard
    var detailPath = NavigationPath()
    var sheet: SheetRoute?
    var cardReloadCallback: (() async -> Void)?

    func navigate(to item: NavigationItem) {
        sidebarSelection = item
        detailPath = NavigationPath()
    }

    func push(_ destination: DetailDestination) {
        detailPath.append(destination)
    }

    func popToRoot() {
        detailPath = NavigationPath()
    }

    func present(_ route: SheetRoute) {
        sheet = route
    }

    func dismissSheet() {
        sheet = nil
    }
}
