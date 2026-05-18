import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class LedgerEditViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_ledger_edit_view() {
        let ledgerRepo = MockLedgerRepository()
        let bankRepo = MockBankRepository()
        let view = LedgerEditView(
            ledger: PreviewLedgers.checking(),
            ledgerRepository: ledgerRepo,
            bankRepository: bankRepo
        )
        verifySnapshots(view)
    }
}
