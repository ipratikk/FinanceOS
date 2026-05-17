import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class CreateNewTargetSheetSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_create_account_target() {
        var state = TargetCreationState()
        state.customName = "Chase Checking"
        state.nickname = "Main"
        state.last4 = "1234"
        state.ownerName = "John Doe"
        state.selectedBankID = PreviewBanks.bankId
        state.isCard = false
        state.accountType = "checking"

        let view = StatefulWrapper(state: state) { binding in
            CreateNewTargetSheet(
                state: binding,
                banks: PreviewBanks.all,
                detectedBank: "Chase",
                onCancel: {},
                onCreate: {}
            )
        }
        verifyComponentSnapshots(view, size: CGSize(width: 520, height: 640))
    }

    func test_create_card_target() {
        var state = TargetCreationState()
        state.customName = "Amex Premium"
        state.last4 = "9999"
        state.ownerName = "John Doe"
        state.selectedBankID = PreviewBanks.bankId
        state.isCard = true
        state.cardType = "amex"
        state.cardProduct = "Premium Rewards"

        let view = StatefulWrapper(state: state) { binding in
            CreateNewTargetSheet(
                state: binding,
                banks: PreviewBanks.all,
                detectedBank: "American Express",
                onCancel: {},
                onCreate: {}
            )
        }
        verifyComponentSnapshots(view, size: CGSize(width: 520, height: 640))
    }
}

private struct StatefulWrapper<Content: View>: View {
    @State var state: TargetCreationState
    let content: (Binding<TargetCreationState>) -> Content

    var body: some View {
        content($state)
    }
}
