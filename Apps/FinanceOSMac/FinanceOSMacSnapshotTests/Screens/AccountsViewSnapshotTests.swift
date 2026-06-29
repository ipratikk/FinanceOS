import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class AccountsViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_accounts_view() {
        let viewModel = AccountsViewModel(graphQLClient: ApolloGraphQLClient())
        viewModel.accounts = PreviewLedgers.all.filter { $0.kind == .bankAccount }
        viewModel.banks = PreviewBanks.all

        let view = AccountsView(viewModel: viewModel)
        verifySnapshots(view)
    }
}
