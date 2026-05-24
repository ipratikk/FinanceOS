import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FDSLabelSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_label_display_large() {
        let view = FDSLabel("$5,234.56")
            .font(AppTypography.displayLarge)
            .foregroundStyle(AppColors.Text.primary)
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 80))
    }

    func test_label_display_medium() {
        let view = FDSLabel("Dashboard")
            .font(AppTypography.displaySmall)
            .foregroundStyle(AppColors.Text.primary)
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 60))
    }

    func test_label_body_medium() {
        let view = FDSLabel("Recent transactions")
            .font(AppTypography.bodyMd)
            .foregroundStyle(AppColors.Text.primary)
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 30))
    }

    func test_label_caption() {
        let view = FDSLabel("This Month")
            .font(AppTypography.captionSm)
            .foregroundStyle(AppColors.Text.primary)
        verifyComponentSnapshots(view, size: CGSize(width: 400, height: 24))
    }
}
