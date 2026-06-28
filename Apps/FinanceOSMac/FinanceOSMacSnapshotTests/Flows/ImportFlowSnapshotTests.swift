import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class ImportFlowSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_import_view() {
        let viewModel = ImportViewModel(
            graphQLClient: ApolloGraphQLClient(),
            bankRepository: MockBankRepository(),
            ledgerRepository: MockLedgerRepository()
        )
        let view = ImportView(viewModel: viewModel)
        verifySnapshots(view)
    }
}
