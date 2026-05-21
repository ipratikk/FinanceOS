import FinanceCore
@testable import FinanceOSMac
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FDSRowSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_row_basic() {
        let view = FDSRow {
            FDSMerchantAvatar(name: "Whole Foods", symbol: "fork.knife", size: 36)
        } content: {
            VStack(alignment: .leading, spacing: 2) {
                FDSLabel("Whole Foods Market")
                    .font(AppTypography.bodySmMedium)
                    .foregroundColor(AppColors.Text.primary)
                FDSLabel("May 18 · Checking")
                    .font(AppTypography.captionSm)
                    .foregroundColor(AppColors.Text.tertiary)
            }
        } trailing: {
            FDSLabel("₹65.43")
                .font(AppTypography.bodySmSemibold)
                .foregroundColor(AppColors.danger)
        }
        verifyFDSComponent(view, size: CGSize(width: 480, height: 96))
    }

    func test_row_empty_trailing() {
        let view = FDSRow {
            Image(systemName: "building.columns.fill")
                .foregroundColor(AppColors.accent)
                .frame(width: 32, height: 32)
        } content: {
            FDSLabel("HDFC Bank")
                .font(AppTypography.bodySmMedium)
                .foregroundColor(AppColors.Text.primary)
        } trailing: {
            EmptyView()
        }
        verifyFDSComponent(view, size: CGSize(width: 480, height: 88))
    }
}
