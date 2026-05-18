import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class FinanceSearchBarSnapshotTests: SnapshotTestable {
    override var record: Bool {
        true
    }

    func test_search_bar_empty() {
        let view = StatefulSearchBar(initialText: "", placeholder: "Search transactions")
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 50))
    }

    func test_search_bar_with_text() {
        let view = StatefulSearchBar(initialText: "Whole Foods", placeholder: "Search")
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 50))
    }
}

private struct StatefulSearchBar: View {
    @State var text: String
    let placeholder: String

    init(initialText: String, placeholder: String) {
        _text = State(initialValue: initialText)
        self.placeholder = placeholder
    }

    var body: some View {
        FinanceSearchBar(placeholder, text: $text)
    }
}
