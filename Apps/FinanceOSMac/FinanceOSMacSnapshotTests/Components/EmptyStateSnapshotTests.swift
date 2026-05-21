import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class EmptyStateSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_empty_state_view() {
        let view = FDSEmptyState(
            symbol: "list.bullet",
            title: "No Transactions",
            subtitle: "Start importing transactions to see them here"
        )
        verifyComponentSnapshots(view, size: CGSize(width: 390, height: 300))
    }

    func test_empty_state_with_action() {
        let view = FDSEmptyState(
            symbol: "creditcard",
            title: "No Cards Yet",
            subtitle: "Add your first credit card to track spending"
        )
        verifyComponentSnapshots(view, size: CGSize(width: 390, height: 360))
    }
}
