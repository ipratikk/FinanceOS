import FinanceCore
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
    var accountReloadCallback: (() async -> Void)?

    var pendingImportTarget: TransactionImportTarget?
    var pendingImportSource: StatementSource?

    let toastPresenter = ToastPresenter()

    func navigate(to item: NavigationItem) {
        sidebarSelection = item
        detailPath = NavigationPath()
    }

    /// Opens the normal import screen preset to `target`. Used by statement reminder deep links.
    func openImport(for target: TransactionImportTarget) {
        pendingImportTarget = target
        navigate(to: .importStatement)
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
