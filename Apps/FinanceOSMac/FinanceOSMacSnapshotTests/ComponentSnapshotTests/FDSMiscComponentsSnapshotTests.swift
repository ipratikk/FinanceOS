import FinanceCore
@testable import FinanceOSMac
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

// MARK: - FDSErrorState

final class FDSErrorStateSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_error_state_basic() {
        let view = FDSErrorState(
            title: "Failed to Load",
            message: "Could not connect to the database. Check your connection and try again.",
            action: {}
        )
        verifyFDSComponent(view, size: CGSize(width: 480, height: 280))
    }

    func test_error_state_custom_action_title() {
        let view = FDSErrorState(
            title: "Import Failed",
            message: "The file format is not supported.",
            actionTitle: "Try Again",
            action: {}
        )
        verifyFDSComponent(view, size: CGSize(width: 480, height: 280))
    }
}

// MARK: - FDSAccountChip

final class FDSAccountChipSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_chip_compact() {
        let view = FDSAccountChip(bankName: "Chase", last4: "1234", style: .compact)
        verifyFDSComponent(view, size: CGSize(width: 240, height: 72))
    }

    func test_chip_prominent() {
        let view = FDSAccountChip(bankName: "HDFC Bank", last4: "5678", style: .prominent)
        verifyFDSComponent(view, size: CGSize(width: 240, height: 88))
    }

    func test_chip_no_last4() {
        let view = FDSAccountChip(bankName: "ICICI Bank", last4: "", style: .compact)
        verifyFDSComponent(view, size: CGSize(width: 240, height: 72))
    }
}

// MARK: - FDSStepper

final class FDSStepperSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_stepper_middle_value() {
        let view = FDSStepper("Statement Day", value: .constant(15))
        verifyFDSComponent(view, size: CGSize(width: 240, height: 72))
    }

    func test_stepper_min_value() {
        let view = FDSStepper("Due Day", value: .constant(1))
        verifyFDSComponent(view, size: CGSize(width: 240, height: 72))
    }

    func test_stepper_max_value() {
        let view = FDSStepper("Day", value: .constant(31))
        verifyFDSComponent(view, size: CGSize(width: 240, height: 72))
    }
}

// MARK: - FDSRadio

final class FDSRadioSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_radio_unselected() {
        let view = FDSRadio(isSelected: .constant(false), label: "Option A")
        verifyFDSComponent(view, size: CGSize(width: 80, height: 64))
    }

    func test_radio_selected() {
        let view = FDSRadio(isSelected: .constant(true), label: "Option B")
        verifyFDSComponent(view, size: CGSize(width: 80, height: 64))
    }

    func test_radio_disabled() {
        let view = FDSRadio(isSelected: .constant(false), label: "Option C", isEnabled: false)
        verifyFDSComponent(view, size: CGSize(width: 80, height: 64))
    }

    func test_radio_group() {
        let view = HStack(spacing: 16) {
            HStack(spacing: 6) {
                FDSRadio(isSelected: .constant(false), label: "Savings")
                FDSLabel("Savings").font(AppTypography.bodySmMedium).foregroundColor(AppColors.Text.primary)
            }
            HStack(spacing: 6) {
                FDSRadio(isSelected: .constant(true), label: "Checking")
                FDSLabel("Checking").font(AppTypography.bodySmMedium).foregroundColor(AppColors.Text.primary)
            }
        }
        verifyFDSComponent(view, size: CGSize(width: 320, height: 72))
    }
}

// MARK: - FDSMetricTile

final class FDSMetricTileSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_metric_tile_basic() {
        let view = FDSMetricTile("Total Spending", value: "₹2,345.67", symbol: "arrow.up.right.circle.fill")
        verifyFDSComponent(view, size: CGSize(width: 240, height: 100))
    }

    func test_metric_tile_with_positive_delta() {
        let view = FDSMetricTile(
            "Income",
            value: "₹5,000.00",
            symbol: "arrow.down.left.circle.fill",
            delta: .init(value: 12.5, period: "vs last month")
        )
        verifyFDSComponent(view, size: CGSize(width: 280, height: 120))
    }

    func test_metric_tile_with_negative_delta() {
        let view = FDSMetricTile(
            "Spending",
            value: "₹2,345.67",
            symbol: "arrow.up.right.circle.fill",
            delta: .init(value: -8.3, period: "vs last month")
        )
        verifyFDSComponent(view, size: CGSize(width: 280, height: 120))
    }

    func test_metric_tile_prominent() {
        let view = FDSMetricTile("Net Flow", value: "₹2,654.33", prominent: true)
        verifyFDSComponent(view, size: CGSize(width: 320, height: 100))
    }

    func test_metric_tiles_row() {
        let view = HStack(spacing: 12) {
            FDSMetricTile("Income", value: "₹5,000", symbol: "arrow.down.left.circle.fill")
            FDSMetricTile("Spending", value: "₹2,345", symbol: "arrow.up.right.circle.fill")
            FDSMetricTile("Txns", value: "47", symbol: "list.bullet")
        }
        verifyFDSComponent(view, size: CGSize(width: 600, height: 100))
    }
}
