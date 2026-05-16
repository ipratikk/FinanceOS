import Foundation

public struct ICICIBankCSVMapper: Sendable {
    public init() {}

    public func map(headerRow: [String]) throws -> [ColumnRole] {
        let normalized = headerRow.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        var roles: [ColumnRole] = []
        for header in normalized {
            switch header {
            case "date":
                roles.append(.date)
            case "mode":
                roles.append(.ignored)
            case "particulars":
                roles.append(.description)
            case "deposits":
                roles.append(.credit)
            case "withdrawals":
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
