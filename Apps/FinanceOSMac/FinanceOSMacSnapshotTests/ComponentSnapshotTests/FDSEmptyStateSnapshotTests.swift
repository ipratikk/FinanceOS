import FinanceCore
@testable import FinanceOSMac
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FDSEmptyStateComponentSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_empty_state_accounts() {
        let view = FDSEmptyState(
            symbol: "building.columns.fill",
            title: "No Accounts",
            subtitle: "Import a statement to get started"
        )
        verifyFDSComponent(view, size: CGSize(width: 480, height: 240))
    }

    func test_empty_state_transactions() {
        let view = FDSEmptyState(
            symbol: "creditcard.fill",
            title: "No Transactions",
            subtitle: "Import statements to get started"
        )
        verifyFDSComponent(view, size: CGSize(width: 480, height: 240))
    }

    func test_empty_state_banks() {
        let view = FDSEmptyState(
            symbol: "building.2.fill",
            title: "No Banks",
            subtitle: "Add a bank when importing your first statement"
        )
        verifyFDSComponent(view, size: CGSize(width: 480, height: 240))
    }

    func test_empty_state_search() {
        let view = FDSEmptyState(
            symbol: "magnifyingglass",
            title: "No Results",
            subtitle: "Try a different search term"
        )
        verifyFDSComponent(view, size: CGSize(width: 480, height: 240))
    }
}
