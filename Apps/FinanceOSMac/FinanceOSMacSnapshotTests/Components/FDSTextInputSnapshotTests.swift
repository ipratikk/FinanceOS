@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FDSTextInputSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_text_input_empty() {
        let view = StatefulTextInput(initial: "", placeholder: "Enter name", isSecure: false)
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 50))
    }

    func test_text_input_filled() {
        let view = StatefulTextInput(initial: "Chase Checking", placeholder: "Name", isSecure: false)
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 50))
    }

    func test_text_input_secure() {
        let view = StatefulTextInput(initial: "password123", placeholder: "Password", isSecure: true)
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 50))
    }
}

private struct StatefulTextInput: View {
    @State var text: String
    let placeholder: String
    let isSecure: Bool

    init(initial: String, placeholder: String, isSecure: Bool) {
        _text = State(initialValue: initial)
        self.placeholder = placeholder
        self.isSecure = isSecure
    }

    var body: some View {
        FDSTextInput(placeholder, text: $text, isSecure: isSecure)
    }
}
