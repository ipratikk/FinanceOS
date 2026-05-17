import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class GlassPanelSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_glass_panel() {
        let view = GlassPanel {
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.headline)
                Text("Body content inside glass")
                    .font(.body)
            }
            .padding()
        }
        verifyComponentSnapshots(view, size: CGSize(width: 320, height: 140))
    }
}
