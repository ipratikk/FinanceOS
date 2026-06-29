import FinanceCore
@testable import FinanceOSMac
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
}
