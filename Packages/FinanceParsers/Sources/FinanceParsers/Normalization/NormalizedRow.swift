import Foundation

/// A single CSV data row after the Mapper stage: column values keyed by `ColumnRole`
/// rather than positional index. Passed to `CSVRowNormalizer.normalize` for final parsing.
public struct NormalizedRow: Sendable, Equatable {
    /// Role-keyed field values for this row; absent roles produce `nil` on subscript.
    public let values: [ColumnRole: String]
    /// Zero-based index of this row in the original file (header row = 0).
    public let rawIndex: Int

    public init(values: [ColumnRole: String], rawIndex: Int) {
        self.values = values
        self.rawIndex = rawIndex
    }

    /// Convenience subscript returning the value for `role`, or `nil` if the role is absent.
    public subscript(_ role: ColumnRole) -> String? {
        values[role]
    }
}
