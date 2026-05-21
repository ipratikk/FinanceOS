import FinanceCore
@testable import FinanceOSMac
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FDSLiquidButtonSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_button_primary() {
        let view = FDSLiquidButton("Save", variant: .primary) {}
        verifyFDSComponent(view, size: CGSize(width: 240, height: 72))
    }

    func test_button_ghost() {
        let view = FDSLiquidButton("Cancel", variant: .ghost) {}
        verifyFDSComponent(view, size: CGSize(width: 240, height: 72))
    }

    func test_button_danger() {
        let view = FDSLiquidButton("Delete Card", symbol: "trash.fill", variant: .danger) {}
        verifyFDSComponent(view, size: CGSize(width: 240, height: 72))
    }

    func test_button_link() {
        let view = FDSLiquidButton("View all transactions", variant: .link) {}
        verifyFDSComponent(view, size: CGSize(width: 280, height: 64))
    }

    func test_button_primary_disabled() {
        let view = FDSLiquidButton("Save", variant: .primary, isEnabled: false) {}
        verifyFDSComponent(view, size: CGSize(width: 240, height: 72))
    }

    func test_button_primary_loading() {
        let view = FDSLiquidButton("Saving…", variant: .primary, isLoading: true) {}
        verifyFDSComponent(view, size: CGSize(width: 240, height: 72))
    }

    func test_button_primary_with_symbol() {
        let view = FDSLiquidButton("Import", symbol: "arrow.down.doc.fill", variant: .primary) {}
        verifyFDSComponent(view, size: CGSize(width: 240, height: 72))
    }

    func test_button_footer_pair() {
        let view = HStack(spacing: 12) {
            FDSLiquidButton("Cancel", variant: .ghost) {}
            Spacer()
            FDSLiquidButton("Save", variant: .primary) {}
        }
        verifyFDSComponent(view, size: CGSize(width: 360, height: 72))
    }
}
