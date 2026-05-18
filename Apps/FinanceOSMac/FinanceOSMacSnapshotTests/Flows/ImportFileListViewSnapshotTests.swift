@testable import FinanceOSMac
import FinanceParsers
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class ImportFileListViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_import_file_list_view() {
        let pairs: [(url: URL, statement: ParsedStatement)] = [
            (URL(fileURLWithPath: "/tmp/chase_jan.csv"), PreviewStatements.sampleStatement()),
            (URL(fileURLWithPath: "/tmp/amex_feb.pdf"), PreviewStatements.sampleStatement())
        ]
        let view = ImportFileListView(fileStatementPairs: pairs)
        verifyComponentSnapshots(view, size: CGSize(width: 600, height: 400))
    }
}
