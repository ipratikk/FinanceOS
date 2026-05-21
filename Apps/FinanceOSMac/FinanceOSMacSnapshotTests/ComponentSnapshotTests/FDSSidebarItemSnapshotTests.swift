import FinanceCore
@testable import FinanceOSMac
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FDSSidebarItemSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_sidebar_item_unselected() {
        let view = FDSSidebarItem("Dashboard", symbol: "square.grid.2x2", isSelected: false) {}
        verifyFDSComponent(view, size: CGSize(width: 240, height: 64))
    }

    func test_sidebar_item_selected() {
        let view = FDSSidebarItem("Dashboard", symbol: "square.grid.2x2", isSelected: true) {}
        verifyFDSComponent(view, size: CGSize(width: 240, height: 64))
    }

    func test_sidebar_item_with_badge() {
        let view = FDSSidebarItem("Transactions", symbol: "list.bullet", isSelected: false, badge: "2,148") {}
        verifyFDSComponent(view, size: CGSize(width: 240, height: 64))
    }

    func test_sidebar_item_selected_with_badge() {
        let view = FDSSidebarItem("Accounts", symbol: "building.columns", isSelected: true, badge: "3") {}
        verifyFDSComponent(view, size: CGSize(width: 240, height: 64))
    }

    func test_sidebar_full_nav() {
        let view = VStack(alignment: .leading, spacing: 0) {
            FDSSidebarSectionHeader("OVERVIEW")
            FDSSidebarItem("Dashboard", symbol: "square.grid.2x2.fill", isSelected: true) {}
            FDSSidebarItem("Analytics", symbol: "chart.bar.fill", isSelected: false) {}
            FDSSidebarSectionHeader("MONEY")
            FDSSidebarItem("Accounts", symbol: "building.columns.fill", isSelected: false) {}
            FDSSidebarItem("Cards", symbol: "creditcard.fill", isSelected: false) {}
            FDSSidebarItem("Transactions", symbol: "list.bullet", isSelected: false) {}
            FDSSidebarSectionHeader("MANAGE")
            FDSSidebarItem("Banks", symbol: "building.2.fill", isSelected: false) {}
            FDSSidebarItem("Settings", symbol: "gearshape.fill", isSelected: false) {}
        }
        .padding(.horizontal, 8)
        verifyFDSComponent(view, size: CGSize(width: 240, height: 420))
    }
}
