import Foundation
import SwiftUI

/// Standard device/window configurations for snapshot testing.
public enum SnapshotDevice: Sendable {
    case macSmall // 1024×768 — minimum window
    case macDefault // 1440×900 — standard
    case macLarge // 1680×1050 — large window
    case macFull // 1920×1080 — full HD

    /// Display name for snapshot naming.
    public var displayName: String {
        switch self {
        case .macSmall:
            "macSmall"
        case .macDefault:
            "macDefault"
        case .macLarge:
            "macLarge"
        case .macFull:
            "macFull"
        }
    }

    /// Size for this configuration.
    public var size: CGSize {
        switch self {
        case .macSmall:
            CGSize(width: 1024, height: 768)
        case .macDefault:
            CGSize(width: 1440, height: 900)
        case .macLarge:
            CGSize(width: 1680, height: 1050)
        case .macFull:
            CGSize(width: 1920, height: 1080)
        }
    }

    /// All configurations.
    public static let allCases: [SnapshotDevice] = [
        .macSmall,
        .macDefault,
        .macLarge,
        .macFull
    ]

    /// Common mac window sizes.
    public static let macWindows: [SnapshotDevice] = [
        .macSmall,
        .macDefault,
        .macLarge
    ]
}
