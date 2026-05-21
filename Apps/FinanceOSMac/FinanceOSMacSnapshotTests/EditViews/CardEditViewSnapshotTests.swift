import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class CardEditViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_card_edit_view() {
        let ledgerRepo = MockLedgerRepository()
        let context = CardEditContext(
            repository: ledgerRepo,
            banks: PreviewBanks.all,
            accounts: PreviewLedgers.all.filter { $0.kind == .bankAccount }
        )
        let view = CardEditView(mode: .edit(PreviewLedgers.creditCard(), context))
        verifySnapshots(view)
    }
}
