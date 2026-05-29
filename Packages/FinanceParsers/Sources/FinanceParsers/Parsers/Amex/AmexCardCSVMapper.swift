import Foundation

/// Maps Amex card CSV column headers to typed `ColumnRole` values.
///
/// The format has exactly 3 columns: "Date" → `.date`, "Description" → `.description`,
/// "Amount" → `.amount`. No sign or debit/credit split column is present.
public struct AmexCardCSVMapper: Sendable, CSVRowMapper {
    public init() {}

    /// Maps the three standard Amex CSV headers; all other columns are ignored.
    public func map(headerRow: [String]) throws -> [ColumnRole] {
        let normalized = headerRow.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        var roles: [ColumnRole] = []
        for header in normalized {
            switch header {
            case "date":
                roles.append(.date)
            case "description":
                roles.append(.description)
            case "amount":
                roles.append(.amount)
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
