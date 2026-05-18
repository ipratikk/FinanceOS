@testable import FinanceOSMac
import FinanceParsers
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class ImportTransactionListViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_import_transaction_list_no_dupes() {
        let view = ImportTransactionListView(
            transactions: PreviewStatements.sampleParsedTransactions(),
            duplicateIndices: []
        )
        verifyComponentSnapshots(view, size: CGSize(width: 700, height: 500))
    }

    func test_import_transaction_list_with_dupes() {
        let view = ImportTransactionListView(
            transactions: PreviewStatements.sampleParsedTransactions(),
            duplicateIndices: [0, 2]
        )
        verifyComponentSnapshots(view, size: CGSize(width: 700, height: 500))
    }
}
