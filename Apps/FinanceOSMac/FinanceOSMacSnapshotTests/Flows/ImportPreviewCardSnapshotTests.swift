@testable import FinanceOSMac
import FinanceParsers
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class ImportPreviewCardSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_import_preview_card() {
        let view = ImportPreviewCard(parsedStatements: [
            PreviewStatements.sampleStatement(),
            PreviewStatements.sampleStatement()
        ])
        verifyComponentSnapshots(view, size: CGSize(width: 600, height: 200))
    }

    func test_import_preview_card_empty() {
        let view = ImportPreviewCard(parsedStatements: [])
        verifyComponentSnapshots(view, size: CGSize(width: 600, height: 200))
    }
}
