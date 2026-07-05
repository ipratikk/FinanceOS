import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class ImportTargetSectionSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_import_target_section_no_selection() {
        let viewModel = ImportViewModel(graphQLClient: ApolloGraphQLClient())
        viewModel.ledgers = [PreviewLedgers.checking(), PreviewLedgers.creditCard()]
        viewModel.banks = [PreviewBanks.hdfc()]
        let view = ImportTargetSection(viewModel: viewModel)
        verifyComponentSnapshots(view, size: CGSize(width: 320, height: 60))
    }

    func test_import_target_section_selected() {
        let viewModel = ImportViewModel(graphQLClient: ApolloGraphQLClient())
        let checking = PreviewLedgers.checking()
        viewModel.ledgers = [checking, PreviewLedgers.creditCard()]
        viewModel.banks = [PreviewBanks.hdfc()]
        viewModel.selectedTarget = .ledger(checking.id)
        let view = ImportTargetSection(viewModel: viewModel)
        verifyComponentSnapshots(view, size: CGSize(width: 320, height: 60))
    }
}
