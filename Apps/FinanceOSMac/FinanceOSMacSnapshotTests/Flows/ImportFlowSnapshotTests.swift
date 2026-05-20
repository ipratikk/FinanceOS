import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class ImportFlowSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_import_view() {
        let transactionRepo = MockTransactionRepository()
        let bankRepo = MockBankRepository()
        let ledgerRepo = MockLedgerRepository()
        let pipeline = TransactionImportPipeline(repository: transactionRepo)
        let viewModel = ImportViewModel(
            transactionImportPipeline: pipeline,
            bankRepository: bankRepo,
            ledgerRepository: ledgerRepo,
            transactionRepository: transactionRepo
        )
        let view = ImportView(viewModel: viewModel)
        verifySnapshots(view)
    }
}
