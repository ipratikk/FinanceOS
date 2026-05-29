import Foundation

/// Maps SBI card CSV column headers to typed `ColumnRole` values.
///
/// "Amount"/"Debit"/"Posted Amount" all map to `.debit` (card spend is the primary flow).
/// "Merchant" is accepted as an alias for the description column.
public struct SBICardCSVMapper: Sendable {
    public init() {}

    /// Matches lowercased, trimmed header strings against known SBI card column name variants.
    public func map(headerRow: [String]) throws -> [ColumnRole] {
        let normalized = headerRow.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        var roles: [ColumnRole] = []
        for header in normalized {
            switch header {
            case "transaction date", "date":
                roles.append(.date)
            case "description", "merchant":
                roles.append(.description)
            case "amount", "debit", "posted amount":
                roles.append(.debit)
            case "credit":
                roles.append(.credit)
            default:
                roles.append(.ignored)
            }
        }

        return roles
    }

    public func mapRow(_ row: [String], using roles: [ColumnRole]) -> NormalizedRow {
        var values: [ColumnRole: String] = [:]

        for (index, role) in roles.enumerated() {
            guard index < row.count, role != .ignored else { continue }
            let value = row[index].trimmingCharacters(in: .whitespaces)
            if !value.isEmpty {
                values[role] = value
            }
        }

        return NormalizedRow(values: values, rawIndex: 0)
    }
}
