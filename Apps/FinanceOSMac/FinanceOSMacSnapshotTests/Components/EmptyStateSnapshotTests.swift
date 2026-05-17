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
}
