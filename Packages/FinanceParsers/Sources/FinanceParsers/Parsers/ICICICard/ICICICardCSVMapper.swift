import Foundation

/// Maps ICICI card CSV column headers to typed `ColumnRole` values.
///
/// Key mappings: "Amount(in Rs)" → `.amount`, "BillingAmountSign" → `.sign`.
public struct ICICICardCSVMapper: Sendable, CSVRowMapper {
    public init() {}

    /// Matches lowercased, trimmed header strings against known ICICI card column names.
    public func map(headerRow: [String]) throws -> [ColumnRole] {
        let normalized = headerRow.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        var roles: [ColumnRole] = []
        for header in normalized {
            switch header {
            case "date":
                roles.append(.date)
            case "transaction details":
                roles.append(.description)
            case "amount(in rs)":
                roles.append(.amount)
            case "billingamountsign":
                roles.append(.sign)
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
