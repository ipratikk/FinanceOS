import FinanceCore
@testable import FinanceOSMac
import FinanceUI
import SnapshotTesting
import SwiftUI
import XCTest

final class FDSBannerSnapshotTests: SnapshotTestable {
    override var record: Bool {
        false
    }

    func test_banner_info() {
        let view = FDSBanner("Statement period: Jan 2025 – Mar 2025.", style: .info)
        verifyFDSComponent(view, size: CGSize(width: 480, height: 72))
    }

    func test_banner_success() {
        let view = FDSBanner("3 transactions imported successfully.", style: .success)
        verifyFDSComponent(view, size: CGSize(width: 480, height: 72))
    }

    func test_banner_warning() {
        let view = FDSBanner("2 rows skipped — duplicate fingerprints detected.", style: .warning, onDismiss: {})
        verifyFDSComponent(view, size: CGSize(width: 480, height: 72))
    }

    func test_banner_error() {
        let view = FDSBanner("Could not parse date in row 14. Check file format.", style: .error, onDismiss: {})
        verifyFDSComponent(view, size: CGSize(width: 480, height: 72))
    }

    func test_banner_neutral() {
        let view = FDSBanner("Showing cached data. Last updated 3 hours ago.", style: .neutral, onDismiss: {})
        verifyFDSComponent(view, size: CGSize(width: 480, height: 72))
    }

    func test_banner_all_styles_stack() {
        let view = VStack(spacing: 8) {
            FDSBanner("Info message", style: .info)
            FDSBanner("Success message", style: .success)
            FDSBanner("Warning message", style: .warning)
            FDSBanner("Error message", style: .error)
            FDSBanner("Neutral message", style: .neutral)
        }
        verifyFDSComponent(view, size: CGSize(width: 480, height: 360))
    }
}
