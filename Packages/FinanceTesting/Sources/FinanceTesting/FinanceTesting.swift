import Foundation

/// FinanceTesting provides snapshot testing infrastructure, test data, and helpers
/// for FinanceOS components and views.
///
/// Key capabilities:
/// - Deterministic snapshot rendering
/// - Device-specific snapshots
/// - Preview data factories
/// - Mock repositories and services
public enum FinanceTesting {
    /// Reference date for deterministic snapshots.
    public static let referenceDate = SnapshotConfiguration.referenceDate
}
