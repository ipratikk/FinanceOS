import XCTest
import SwiftUI
import SnapshotTesting
import FinanceTesting

extension XCTestCase {
    /// Verify snapshots in light and dark modes.
    func verifySnapshots<V: View>(
        _ view: V,
        device: SnapshotDevice = .iPhone16Pro,
        record: Bool = false,
        file: StaticString = #file,
        testName: String = #function
    ) {
        let deviceConfig = device.snapshotTestingConfig

        // Light mode
        assertSnapshot(
            of: view.environment(\.colorScheme, .light),
            as: .image(layout: .device(config: deviceConfig)),
            named: "\(device.displayName).Light",
            record: record,
            file: file,
            testName: testName
        )

        // Dark mode
        assertSnapshot(
            of: view.environment(\.colorScheme, .dark),
            as: .image(layout: .device(config: deviceConfig)),
            named: "\(device.displayName).Dark",
            record: record,
            file: file,
            testName: testName
        )
    }

    /// Verify snapshots across multiple devices.
    func verifySnapshotsAcrossDevices<V: View>(
        _ view: V,
        devices: [SnapshotDevice] = SnapshotDevice.mobileDevices,
        record: Bool = false,
        file: StaticString = #file,
        testName: String = #function
    ) {
        for device in devices {
            let deviceConfig = device.snapshotTestingConfig

            // Light mode
            assertSnapshot(
                of: view.environment(\.colorScheme, .light),
                as: .image(layout: .device(config: deviceConfig)),
                named: "\(device.displayName).Light",
                record: record,
                file: file,
                testName: testName
            )

            // Dark mode
            assertSnapshot(
                of: view.environment(\.colorScheme, .dark),
                as: .image(layout: .device(config: deviceConfig)),
                named: "\(device.displayName).Dark",
                record: record,
                file: file,
                testName: testName
            )
        }
    }

    /// Verify component snapshot with fixed size.
    func verifyComponentSnapshots<V: View>(
        _ view: V,
        size: CGSize = CGSize(width: 390, height: 200),
        record: Bool = false,
        file: StaticString = #file,
        testName: String = #function
    ) {
        // Light mode
        assertSnapshot(
            of: view
                .frame(width: size.width, height: size.height)
                .environment(\.colorScheme, .light),
            as: .image(layout: .fixed(width: Int(size.width), height: Int(size.height))),
            named: "Light",
            record: record,
            file: file,
            testName: testName
        )

        // Dark mode
        assertSnapshot(
            of: view
                .frame(width: size.width, height: size.height)
                .environment(\.colorScheme, .dark),
            as: .image(layout: .fixed(width: Int(size.width), height: Int(size.height))),
            named: "Dark",
            record: record,
            file: file,
            testName: testName
        )
    }
}

extension SnapshotDevice {
    /// SnapshotTesting device configuration.
    var snapshotTestingConfig: ViewImageConfig {
        switch self {
        case .iPhone16Pro:
            .iPhone14Pro
        case .iPhoneSE:
            .iPhoneSE
        case .iPadPro:
            .iPadPro
        case .macOS:
            .fixed(width: 1200, height: 800)
        }
    }
}
