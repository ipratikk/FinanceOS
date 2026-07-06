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
        let viewModel = ImportViewModel(graphQLClient: ApolloGraphQLClient())
        let view = ImportView(viewModel: viewModel)
        verifySnapshots(view)
    }

    // Note: these two exercise `readyToImportContent` directly rather than the full
    // `ImportView` — `ImportView.onAppear` unconditionally fires a real
    // `loadTargetsOnAppear()` network fetch, which (when a local backend happens to be
    // running) races the fixture setup below and overwrites `viewModel.ledgers`/`banks`
    // with live data, making a full-`ImportView` snapshot here non-deterministic.

    func test_import_view_ready_to_import_auto_matched() {
        let viewModel = ImportViewModel(graphQLClient: ApolloGraphQLClient())
        let checking = PreviewLedgers.checking()
        viewModel.ledgers = [checking, PreviewLedgers.creditCard()]
        viewModel.banks = [PreviewBanks.hdfc()]
        viewModel.fileURLs = [URL(fileURLWithPath: "/tmp/statement.csv")]
        viewModel.parsedStatements = [
            ParsedStatement(bankName: "HDFC", accountName: "Test", accountLast4: "1234")
        ]
        viewModel.selectedTarget = .ledger(checking.id)
        viewModel.phase = .readyToImport
        let view = ImportView(viewModel: viewModel)
        verifySnapshots(view.readyToImportContent)
    }

    func test_import_view_ready_to_import_needs_pick() {
        let viewModel = ImportViewModel(graphQLClient: ApolloGraphQLClient())
        viewModel.ledgers = [PreviewLedgers.checking(), PreviewLedgers.creditCard()]
        viewModel.banks = [PreviewBanks.hdfc()]
        viewModel.fileURLs = [URL(fileURLWithPath: "/tmp/statement.csv")]
        viewModel.parsedStatements = [
            ParsedStatement(bankName: "Unknown Bank", accountName: "Test")
        ]
        viewModel.phase = .readyToImport
        let view = ImportView(viewModel: viewModel)
        verifySnapshots(view.readyToImportContent)
    }
}
