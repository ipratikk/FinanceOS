import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class EmptyStateSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_empty_state_view() {
        let view = EmptyStateView(
            icon: "list.bullet",
            title: "No Transactions",
            subtitle: "Start importing transactions to see them here"
        )
        verifyComponentSnapshots(view, size: CGSize(width: 390, height: 300))
    }

    func test_empty_state_with_action() {
        let view = EmptyStateView(
            icon: "creditcard",
            title: "No Cards Yet",
            subtitle: "Add your first credit card to track spending",
            action: {},
            actionLabel: "Add Card"
        )
        verifyComponentSnapshots(view, size: CGSize(width: 390, height: 360))
    }
}
