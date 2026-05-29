import Foundation

/// Maps HDFC card statement `~|~`-delimited column headers to `ColumnRole` values.
///
/// Key mappings: "Amt" → `.amount`, "Debit /Credit" → `.sign`.
/// The sign column disambiguates spend (DR) from payment/refund (CR).
public struct HDFCCardCSVMapper: Sendable, CSVRowMapper {
    public init() {}

    /// Recognises "Date", "Transaction Details"/"Description", "Amt", and "Debit /Credit".
    public func map(headerRow: [String]) throws -> [ColumnRole] {
        let normalized = headerRow.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        var roles: [ColumnRole] = []
        for header in normalized {
            switch header {
            case "date":
                roles.append(.date)
            case "description", "transaction details":
                roles.append(.description)
            case "amt":
                roles.append(.amount)
            case "debit /credit":
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
