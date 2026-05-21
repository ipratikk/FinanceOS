import FinanceCore
@testable import FinanceOSMac
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FDSToggleSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_toggle_off() {
        let view = FDSToggle(isOn: .constant(false), label: "Notifications")
        verifyFDSComponent(view, size: CGSize(width: 120, height: 64))
    }

    func test_toggle_on() {
        let view = FDSToggle(isOn: .constant(true), label: "Auto-Refresh")
        verifyFDSComponent(view, size: CGSize(width: 120, height: 64))
    }

    func test_toggle_disabled_off() {
        let view = FDSToggle(isOn: .constant(false), label: "Disabled", isEnabled: false)
        verifyFDSComponent(view, size: CGSize(width: 120, height: 64))
    }

    func test_toggle_disabled_on() {
        let view = FDSToggle(isOn: .constant(true), label: "Disabled On", isEnabled: false)
        verifyFDSComponent(view, size: CGSize(width: 120, height: 64))
    }

    func test_toggle_settings_row_off() {
        let view = HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .font(AppTypography.bodySmMedium)
                .foregroundColor(AppColors.Text.secondary)
                .frame(width: 22)
            FDSLabel("Notifications")
                .font(AppTypography.bodySmMedium)
                .foregroundColor(AppColors.Text.primary)
            Spacer()
            FDSToggle(isOn: .constant(false), label: "Notifications")
        }
        verifyFDSComponent(view, size: CGSize(width: 360, height: 64))
    }

    func test_toggle_settings_row_on() {
        let view = HStack(spacing: 12) {
            Image(systemName: "arrow.clockwise")
                .font(AppTypography.bodySmMedium)
                .foregroundColor(AppColors.Text.secondary)
                .frame(width: 22)
            FDSLabel("Auto-Refresh")
                .font(AppTypography.bodySmMedium)
                .foregroundColor(AppColors.Text.primary)
            Spacer()
            FDSToggle(isOn: .constant(true), label: "Auto-Refresh")
        }
        verifyFDSComponent(view, size: CGSize(width: 360, height: 64))
    }
}
