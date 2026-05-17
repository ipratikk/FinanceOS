import Testing
import SwiftUI
@testable import FinanceOSMac

/// Snapshot tests for SidebarView across themes and states.
@Suite
struct SidebarViewSnapshotTests {
    @Test("Sidebar light theme")
    func sidebarLightTheme() {
        // TODO: Create sidebar snapshots
        // let view = SidebarView()
        //     .snapshotEnvironment()
        //     .snapshotTheme(.light)
        //
        // assertSnapshot(of: view, as: .image, named: "SidebarView.light")
    }

    @Test("Sidebar dark theme")
    func sidebarDarkTheme() {
        // TODO: Create sidebar snapshots
        // let view = SidebarView()
        //     .snapshotEnvironment()
        //     .snapshotTheme(.dark)
        //
        // assertSnapshot(of: view, as: .image, named: "SidebarView.dark")
    }

    @Test("Sidebar dashboard selected")
    func sidebarDashboardSelected() {
        // TODO: Test with dashboard item selected
    }

    @Test("Sidebar accounts selected")
    func sidebarAccountsSelected() {
        // TODO: Test with accounts item selected
    }

    @Test("Sidebar expanded width")
    func sidebarExpandedWidth() {
        // TODO: Test sidebar at expanded width
    }

    @Test("Sidebar compact width")
    func sidebarCompactWidth() {
        // TODO: Test sidebar at compact width
    }
}
