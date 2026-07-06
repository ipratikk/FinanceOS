import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class SettingsViewSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_settings_view() {
        let viewModel = SettingsViewModel(graphQLClient: ApolloGraphQLClient())
        verifySnapshots(SettingsView(viewModel: viewModel))
    }
}
