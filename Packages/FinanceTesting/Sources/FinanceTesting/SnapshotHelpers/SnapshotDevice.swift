import Foundation
import SwiftUI

/// Standard device configurations for snapshot testing.
public enum SnapshotDevice {
    case iPhone16Pro
    case iPhoneSE
    case iPadPro
    case macOS

    /// Display name for snapshot naming.
    public var displayName: String {
        switch self {
        case .iPhone16Pro:
            "iPhone16Pro"
        case .iPhoneSE:
            "iPhoneSE"
        case .iPadPro:
            "iPadPro"
        case .macOS:
            "macOS"
        }
    }

    /// Size for this device.
    public var size: CGSize {
        switch self {
        case .iPhone16Pro:
            CGSize(width: 393, height: 852)
        case .iPhoneSE:
            CGSize(width: 375, height: 667)
        case .iPadPro:
            CGSize(width: 1024, height: 1366)
        case .macOS:
            CGSize(width: 1200, height: 800)
        }
    }

    /// Safe area insets for this device (top, bottom).
    public var safeAreaInsets: (top: CGFloat, bottom: CGFloat) {
        switch self {
        case .iPhone16Pro:
            (top: 59, bottom: 34)
        case .iPhoneSE:
            (top: 20, bottom: 0)
        case .iPadPro:
            (top: 24, bottom: 20)
        case .macOS:
            (top: 0, bottom: 0)
        }
    }

    /// All standard devices for comprehensive snapshot coverage.
    public static let allCases: [SnapshotDevice] = [
        .iPhone16Pro,
        .iPhoneSE,
        .iPadPro,
        .macOS
    ]

    /// Mobile devices (iPhone, iPad).
    public static let mobileDevices: [SnapshotDevice] = [
        .iPhone16Pro,
        .iPhoneSE,
        .iPadPro
    ]

    /// iOS-only devices.
    public static let iOSDevices: [SnapshotDevice] = [
        .iPhone16Pro,
        .iPhoneSE
    ]
}
