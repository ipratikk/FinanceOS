import FinanceCore
@testable import FinanceOSMac
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FDSCardSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_card_padded_default() {
        let view = FDSCard {
            FDSLabel("Card content")
                .font(AppTypography.bodySmMedium)
                .foregroundColor(AppColors.Text.primary)
        }
        verifyFDSComponent(view, size: CGSize(width: 360, height: 100))
    }

    func test_card_unpadded() {
        let view = FDSCard(padded: false) {
            FDSLabel("Unpadded card")
                .font(AppTypography.bodySmMedium)
                .foregroundColor(AppColors.Text.primary)
                .padding(8)
        }
        verifyFDSComponent(view, size: CGSize(width: 360, height: 100))
    }

    func test_card_small_corner_radius() {
        let view = FDSCard(cornerRadius: 8, padded: false) {
            FDSLabel("Tight radius card")
                .font(AppTypography.captionSmMedium)
                .foregroundColor(AppColors.Text.secondary)
                .padding(12)
        }
        verifyFDSComponent(view, size: CGSize(width: 360, height: 80))
    }

    func test_card_with_vstack_content() {
        let view = FDSCard(cornerRadius: 12, padded: false) {
            VStack(alignment: .leading, spacing: 8) {
                FDSLabel("Total Spending")
                    .font(AppTypography.captionSmSemibold)
                    .foregroundColor(AppColors.Text.secondary)
                FDSLabel("₹2,345.67")
                    .font(AppTypography.headingSmall)
                    .foregroundColor(AppColors.danger)
            }
            .padding(12)
        }
        verifyFDSComponent(view, size: CGSize(width: 300, height: 120))
    }
}
