import Foundation

/// Maps HDFC bank TXT statement column headers to typed `ColumnRole` values.
///
/// Handles both the fixed-width synthetic header and the comma-delimited header.
/// Recognises "Withdrawal Amt." as `.debit` and "Deposit Amt." as `.credit`.
public struct HDFCBankTXTMapper: Sendable, CSVRowMapper {
    public init() {}

    /// Matches lowercased, trimmed header strings against known HDFC column name variants.
    public func map(headerRow: [String]) throws -> [ColumnRole] {
        let normalized = headerRow.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        var roles: [ColumnRole] = []
        for header in normalized {
            switch header {
            case "date":
                roles.append(.date)
            case "narration":
                roles.append(.description)
            case "valuedat", "value dat", "value dt":
                roles.append(.ignored)
            case "debitamount", "debit amount", "withdrawal amt.", "withdrawal amt":
                roles.append(.debit)
            case "creditamount", "credit amount", "deposit amt.", "deposit amt":
                roles.append(.credit)
            case "chq/refnumber", "chq/ref number", "chq./ref.no.", "chq/ref.no.", "chq./ref.no":
                roles.append(.reference)
            case "closingbalance", "closing balance":
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
