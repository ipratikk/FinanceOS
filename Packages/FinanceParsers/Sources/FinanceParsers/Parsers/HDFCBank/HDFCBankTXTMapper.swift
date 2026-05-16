import Foundation

public struct HDFCBankTXTMapper: Sendable {
    public init() {}

    public func map(headerRow: [String]) throws -> [ColumnRole] {
        let normalized = headerRow.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        var roles: [ColumnRole] = []
        for header in normalized {
            switch header {
            case "date":
                roles.append(.date)
            case "narration":
                roles.append(.description)
            case "valuedat":
                roles.append(.ignored)
            case "debitamount":
                roles.append(.debit)
            case "creditamount":
                roles.append(.credit)
            case "chq/refnumber":
                roles.append(.reference)
            case "closingbalance":
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
