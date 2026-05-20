@testable import FinanceOSMac
import FinanceCore
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest
#if os(macOS)
import AppKit
#endif

/// Base class for snapshot tests in FinanceOS.
///
/// Wraps test views with:
/// - NavigationStack (for nav context)
/// - AppNavigator environment object
/// - Deterministic env (locale, timezone)
/// - Forces dark color scheme (app is dark-only)
///
/// Subclasses:
/// - Override `record` (defaults to false)
/// - Call `verifySnapshots(view)` from test methods
@MainActor
class SnapshotTestable: XCTestCase {
    private var testContainer: AppContainer!

    override func setUp() {
        super.setUp()
        // Create in-memory database for this test to avoid locking issues
        do {
            let testDatabaseManager = try DatabaseManager(inMemory: true)
            testContainer = AppContainer(databaseManager: testDatabaseManager)
        } catch {
            fatalError("Failed to initialize test database: \(error)")
        }
    }

    /// Set to true in subclass to record new snapshots.
    var record: Bool {
        false
    }

    /// Verify snapshot at device size in dark mode.
    func verifySnapshots(
        _ view: some View,
        device: SnapshotDevice = .macDefault,
        file: StaticString = #file,
        testName: String = #function
    ) {
        let wrapped = wrap(view)
        let size = device.size
        let host = makeHostingView(wrapped, size: size)

        assertSnapshot(
            of: host,
            as: .image(precision: 0.99, size: size),
            named: device.displayName,
            record: record,
            file: file,
            testName: testName
        )
    }

    /// Verify component snapshot with fixed size in dark mode.
    func verifyComponentSnapshots(
        _ view: some View,
        size: CGSize = CGSize(width: 390, height: 200),
        file: StaticString = #file,
        testName: String = #function
    ) {
        let wrapped = wrap(view)
        let host = makeHostingView(wrapped, size: size)

        assertSnapshot(
            of: host,
            as: .image(precision: 0.95, perceptualPrecision: 0.95, size: size),
            named: "default",
            record: record,
            file: file,
            testName: testName
        )
    }

    /// Verify snapshots across multiple devices in dark mode.
    func verifySnapshotsAcrossDevices(
        _ view: some View,
        devices: [SnapshotDevice] = SnapshotDevice.macWindows,
        file: StaticString = #file,
        testName: String = #function
    ) {
        let wrapped = wrap(view)
        for device in devices {
            let size = device.size
            let host = makeHostingView(wrapped, size: size)

            assertSnapshot(
                of: host,
                as: .image(precision: 0.99, size: size),
                named: device.displayName,
                record: record,
                file: file,
                testName: testName
            )
        }
    }

    /// Wrap view in NavigationStack with default environment + forced dark.
    private func wrap(_ view: some View) -> some View {
        NavigationStack {
            view
        }
        .environment(AppNavigator())
        .environment(\.timeZone, SnapshotConfiguration.timeZone)
        .environment(\.locale, SnapshotConfiguration.locale)
        .preferredColorScheme(.dark)
        .transaction { $0.disablesAnimations = true }
        .animation(nil, value: UUID())
    }

    #if os(macOS)
    private func makeHostingView(_ view: some View, size: CGSize) -> NSView {
        let wrapped = view
            .environment(\.colorScheme, .dark)
            .frame(width: size.width, height: size.height)
        let hostingView = NSHostingView(rootView: wrapped)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.appearance = NSAppearance(named: .darkAqua)

        // Force the view into a window so .task fires + layout completes.
        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView

        // Pump runloop to let .task modifiers fire + complete async loads.
        let runloop = RunLoop.current
        let deadline = Date().addingTimeInterval(0.5)
        while runloop.run(mode: .default, before: Date().addingTimeInterval(0.05)) {
            if Date() >= deadline { break }
        }

        return hostingView
    }
    #endif
}
