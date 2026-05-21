@testable import FinanceOSMac
import FinanceParsers
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class ImportTransactionListViewSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_import_transaction_list_no_dupes() {
        let view = ImportTransactionListView(
            transactions: PreviewStatements.sampleParsedTransactions(),
            duplicateIndices: Set<Int>()
        )
        verifyComponentSnapshots(view, size: CGSize(width: 700, height: 500))
    }

    func test_import_transaction_list_with_dupes() {
        let view = ImportTransactionListView(
            transactions: PreviewStatements.sampleParsedTransactions(),
            duplicateIndices: Set([0, 2])
        )
        verifyComponentSnapshots(view, size: CGSize(width: 700, height: 500))
    }

    func test_import_transaction_list_with_row_limit() {
        let view = ImportTransactionListView(
            transactions: PreviewStatements.sampleParsedTransactions(),
            duplicateIndices: Set([1]),
            rowLimit: 5
        )
        verifyComponentSnapshots(view, size: CGSize(width: 700, height: 500))
    }
}
