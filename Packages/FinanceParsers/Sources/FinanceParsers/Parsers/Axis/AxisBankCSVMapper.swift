import Foundation

public struct AxisBankCSVMapper: Sendable {
    public init() {}

    public func map(headerRow: [String]) throws -> [ColumnRole] {
        let normalized = headerRow.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        var roles: [ColumnRole] = []
        for header in normalized {
            switch header {
            case "tran. date", "transaction date":
                roles.append(.date)
            case "description":
                roles.append(.description)
            case "cheque no.", "cheque no":
                roles.append(.ignored)
            case "deposit", "credit":
                roles.append(.credit)
            case "withdrawal", "debit":
                roles.append(.debit)
            case "balance":
                roles.append(.balance)
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
