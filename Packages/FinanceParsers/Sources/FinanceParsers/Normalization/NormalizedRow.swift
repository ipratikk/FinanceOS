import Foundation

public struct NormalizedRow: Sendable, Equatable {
    public let values: [ColumnRole: String]
    public let rawIndex: Int

    public init(values: [ColumnRole: String], rawIndex: Int) {
        self.values = values
        self.rawIndex = rawIndex
    }

    public subscript(_ role: ColumnRole) -> String? {
        values[role]
    }
}
