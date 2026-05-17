import Testing
import SwiftUI
@testable import FinanceOSMac

/// Snapshot tests for DashboardView across themes and devices.
@Suite
struct DashboardViewSnapshotTests {
    @Test("Dashboard light mode snapshot")
    func dashboardLightMode() {
        // TODO: Create snapshot once DashboardView is fully wired with preview state
        // let view = DashboardView(viewModel: DashboardViewModel.preview)
        //     .snapshotEnvironment()
        //     .snapshotTheme(.light)
        //
        // assertSnapshot(of: view, as: .image, named: "DashboardView.light")
    }

    @Test("Dashboard dark mode snapshot")
    func dashboardDarkMode() {
        // TODO: Create snapshot once DashboardView is fully wired with preview state
        // let view = DashboardView(viewModel: DashboardViewModel.preview)
        //     .snapshotEnvironment()
        //     .snapshotTheme(.dark)
        //
        // assertSnapshot(of: view, as: .image, named: "DashboardView.dark")
    }

    @Test("Dashboard with empty state")
    func dashboardEmptyState() {
        // TODO: Test with empty account list
    }

    @Test("Dashboard with large dynamic type")
    func dashboardLargeDynamicType() {
        // TODO: Test with accessibility size
    }

    @Test("Dashboard across all devices")
    func dashboardAllDevices() {
        // TODO: Generate snapshots for all devices
        // for device in SnapshotDevice.mobileDevices {
        //     let view = DashboardView(viewModel: DashboardViewModel.preview)
        //         .snapshotEnvironment()
        //         .frame(width: device.size.width, height: device.size.height)
        //
        //     let name = SnapshotNaming.namedWithDevice("DashboardView", device: device)
        //     assertSnapshot(of: view, as: .image, named: name)
        // }
    }
}
