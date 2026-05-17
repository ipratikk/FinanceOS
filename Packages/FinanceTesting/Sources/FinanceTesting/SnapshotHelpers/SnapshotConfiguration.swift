import Foundation

/// Configuration for deterministic snapshot rendering.
public struct SnapshotConfiguration {
    /// Reference date for all snapshot tests (2025-05-15 09:30:00).
    public static let referenceDate = Date(timeIntervalSince1970: 1_747_843_800)

    /// Default snapshot configuration.
    public static let `default` = SnapshotConfiguration()

    /// Disable animations for snapshots.
    public var animationsDisabled: Bool = true

    /// Force a specific time zone for tests (UTC).
    public var timeZone: TimeZone = TimeZone(abbreviation: "UTC") ?? .current

    /// Force a specific locale for tests (en_US).
    public var locale: Locale = Locale(identifier: "en_US")

    /// Enable deterministic async loading states.
    public var deterministic: Bool = true

    /// Fixed random seed for reproducible "random" values.
    public var randomSeed: UInt64 = 42

    /// Should use light color scheme in snapshots.
    public var useLightColorScheme: Bool = true

    /// Default snapshot size for components.
    public var componentSize: CGSize = CGSize(width: 390, height: 844)

    /// Default snapshot size for full screens.
    public var screenSize: CGSize = CGSize(width: 390, height: 844)

    /// macOS window snapshot size.
    public var macOSWindowSize: CGSize = CGSize(width: 1200, height: 800)

    /// iPad snapshot size.
    public var iPadSize: CGSize = CGSize(width: 1024, height: 1366)

    public init() {}
}
