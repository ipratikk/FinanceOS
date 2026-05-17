import Foundation

/// Configuration for deterministic snapshot rendering.
///
/// Use with XCTest + SnapshotTesting framework for consistent snapshots.
public enum SnapshotConfiguration {
    /// Reference date for all snapshot tests (2025-05-18 00:00:00 UTC).
    public static let referenceDate = Date(timeIntervalSince1970: 1_747_900_800)

    /// Standard locale for all snapshots (en_US).
    public static let locale = Locale(identifier: "en_US")

    /// Standard time zone for all snapshots (UTC).
    public static let timeZone = TimeZone(abbreviation: "UTC") ?? .current
}
