import Foundation

public struct ICICIStatementDetector: StatementDetector {
    public init() {}

    public func detect(from rows: [[String]]) -> DetectedStatementMetadata? {
        guard let firstRow = rows.first else { return nil }
        guard let firstCell = firstRow.first else { return nil }

        let isICICI = firstCell.lowercased().contains("accountno")
        guard isICICI else { return nil }

        let accountName = rows.count > 1 ? extractValue(rows[1]) : "Unknown"
        let cardLast4 = rows.count > 7 ? extractCardLast4(rows[7]) : nil

        return DetectedStatementMetadata(
            institution: "ICICI",
            accountName: accountName,
            cardLast4: cardLast4,
            transactionStartIndex: 6
        )
    }

    private func extractValue(_ row: [String]) -> String {
        guard row.count >= 2 else { return "Unknown" }
        return value(at: 1, in: row)
    }

    private func extractCardLast4(_ row: [String]) -> String? {
        guard let cardString = row.first else { return nil }
        let digits = String(cardString.filter(\.isNumber))
        guard digits.count >= 4 else { return nil }
        return String(digits.suffix(4))
    }

    private func value(at index: Int, in row: [String]) -> String {
        guard row.indices.contains(index) else {
            return ""
        }

        return row[index]
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
