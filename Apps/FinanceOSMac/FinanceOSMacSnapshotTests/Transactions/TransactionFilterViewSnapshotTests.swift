@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class TransactionFilterViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_transaction_filter_view() {
        let state = TransactionListState()
        let view = TransactionFilterView(listState: state)
        verifyComponentSnapshots(view, size: CGSize(width: 480, height: 640))
    }
}
