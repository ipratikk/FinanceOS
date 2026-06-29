import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class BankEditViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_bank_edit_view() {
        let context = BankEditContext(graphQLClient: ApolloGraphQLClient())
        let view = BankEditView(bank: PreviewBanks.hdfc(), context: context)
        verifySnapshots(view)
    }
}
