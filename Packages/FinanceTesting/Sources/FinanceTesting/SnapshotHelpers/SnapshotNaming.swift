import Foundation
import SwiftUI

/// Helpers for consistent snapshot naming conventions.
public enum SnapshotNaming {
    /// Generate snapshot name with theme and device suffix.
    public static func named(
        _ baseName: String,
        theme: SnapshotTheme = .light,
        device: SnapshotDevice = .iPhone16Pro
    ) -> String {
        if device == .iPhone16Pro, theme == .light {
            return baseName
        }
        let themeSuffix = theme == .light ? "light" : "dark"
        let deviceSuffix = device.displayName
        return "\(baseName).\(themeSuffix).\(deviceSuffix)"
    }

    /// Generate snapshot name with only theme suffix.
    public static func namedWithTheme(
        _ baseName: String,
        theme: SnapshotTheme = .light
    ) -> String {
        let themeSuffix = theme == .light ? "light" : "dark"
        return "\(baseName).\(themeSuffix)"
    }

    /// Generate snapshot name with only device suffix.
    public static func namedWithDevice(
        _ baseName: String,
        device: SnapshotDevice = .iPhone16Pro
    ) -> String {
        let deviceSuffix = device.displayName
        return "\(baseName).\(deviceSuffix)"
    }

    /// Generate snapshot names for all devices.
    public static func namedForAllDevices(
        _ baseName: String,
        theme: SnapshotTheme = .light
    ) -> [String] {
        SnapshotDevice.allCases.map {
            named(baseName, theme: theme, device: $0)
        }
    }

    /// Generate snapshot names for all themes.
    public static func namedForAllThemes(
        _ baseName: String,
        device: SnapshotDevice = .iPhone16Pro
    ) -> [String] {
        [
            named(baseName, theme: .light, device: device),
            named(baseName, theme: .dark, device: device)
        ]
    }

    /// Generate snapshot names for all combinations.
    public static func namedForAllCombinations(
        _ baseName: String
    ) -> [String] {
        var names: [String] = []
        for device in SnapshotDevice.allCases {
            for theme in [SnapshotTheme.light, SnapshotTheme.dark] {
                names.append(named(baseName, theme: theme, device: device))
            }
        }
        return names
    }
}

/// Theme variants for snapshot testing.
public enum SnapshotTheme: Sendable {
    case light
    case dark

    public var displayName: String {
        switch self {
        case .light:
            "light"
        case .dark:
            "dark"
        }
    }

    public var colorScheme: ColorScheme {
        switch self {
        case .light:
            .light
        case .dark:
            .dark
        }
    }

    public static let allCases: [SnapshotTheme] = [.light, .dark]
}
