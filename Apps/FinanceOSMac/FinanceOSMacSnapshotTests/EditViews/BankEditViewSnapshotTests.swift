import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class BankEditViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_bank_edit_view() {
        let bankRepo = MockBankRepository()
        let ledgerRepo = MockLedgerRepository()
        let context = BankEditContext(repository: bankRepo, ledgerRepository: ledgerRepo)
        let view = BankEditView(bank: PreviewBanks.chase(), context: context)
        verifySnapshots(view)
    }
}
