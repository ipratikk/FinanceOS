import FinanceCore
@testable import FinanceOSMac
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FDSGlassSurfaceSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_glass_surface_basic() {
        let view = FDSGlassSurface(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: 8) {
                FDSLabel("BASIC INFORMATION")
                    .font(AppTypography.captionSmSemibold)
                    .foregroundColor(AppColors.Text.secondary)
                FDSLabel("Card name or account details go here")
                    .font(AppTypography.bodySmMedium)
                    .foregroundColor(AppColors.Text.primary)
            }
        }
        verifyFDSComponent(view, size: CGSize(width: 480, height: 140))
    }

    func test_glass_surface_danger_zone() {
        let view = FDSGlassSurface(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: 12) {
                FDSLabel("DANGER ZONE")
                    .font(AppTypography.captionSmSemibold)
                    .foregroundColor(AppColors.Text.secondary)
                FDSLiquidButton("Delete Card", symbol: "trash.fill", variant: .danger) {}
            }
        }
        verifyFDSComponent(view, size: CGSize(width: 480, height: 140))
    }
}
