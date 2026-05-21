import FinanceCore
@testable import FinanceOSMac
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FDSListRowSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_list_row_basic() {
        let view = FDSListRow(title: "Chase Checking", subtitle: "••••1234")
        verifyFDSComponent(view, size: CGSize(width: 480, height: 88))
    }

    func test_list_row_with_icon() {
        let view = FDSListRow(
            title: "HDFC Bank",
            subtitle: "Savings account",
            icon: Image(systemName: "building.columns.fill")
        )
        verifyFDSComponent(view, size: CGSize(width: 480, height: 88))
    }

    func test_list_row_selected() {
        let view = FDSListRow(
            title: "Amex Platinum",
            subtitle: "••••9999",
            icon: Image(systemName: "creditcard.fill"),
            isSelected: true
        )
        verifyFDSComponent(view, size: CGSize(width: 480, height: 88))
    }

    func test_list_row_with_trailing_amount() {
        let view = FDSListRow(
            title: "Chase Checking",
            subtitle: "Checking · ••••1234",
            icon: Image(systemName: "building.columns.fill")
        ) {
            FDSLabel("₹1,23,456.78")
                .font(AppTypography.bodySmSemibold)
                .foregroundColor(AppColors.Text.primary)
        }
        verifyFDSComponent(view, size: CGSize(width: 480, height: 88))
    }

    func test_list_row_title_only() {
        let view = FDSListRow(title: "ICICI Bank")
        verifyFDSComponent(view, size: CGSize(width: 480, height: 72))
    }
}
