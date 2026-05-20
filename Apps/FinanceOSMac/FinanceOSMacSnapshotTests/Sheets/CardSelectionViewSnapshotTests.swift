@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class CardSelectionViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_card_selection_view() {
        let view = CardSelectionView(
            onSelect: { _ in },
            onDismiss: {}
        )
        verifyComponentSnapshots(view, size: CGSize(width: 600, height: 720))
    }
}
