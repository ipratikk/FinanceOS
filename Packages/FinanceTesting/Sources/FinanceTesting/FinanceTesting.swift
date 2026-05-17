import Foundation

/// FinanceTesting provides snapshot testing infrastructure, test data, and helpers
/// for FinanceOS components and views.
///
/// Key capabilities:
/// - Deterministic snapshot rendering
/// - Theme/device-specific snapshots
/// - Preview data factories
/// - Mock repositories and services
/// - Snapshot helpers for common patterns
public enum FinanceTesting {
    /// Snapshot testing configuration.
    public static let current = SnapshotConfiguration.default
}
