import Foundation

/// Serializes evaluated statement status into a flat dataset for the wedding dashboard (JSON + CSV).
/// Output is deterministic for identical input: sorted keys, fixed date formats, UTC dates.
public enum DashboardDatasetExporter {
    public static let schemaVersion = 1

    public struct Dataset: Codable, Sendable, Equatable {
        public let schemaVersion: Int
        public let generatedAt: Date
        public let ledgers: [Record]
    }

    public struct Record: Codable, Sendable, Equatable {
        public let ledgerId: String
        public let displayName: String
        public let kind: String
        public let bankName: String
        public let last4: String
        /// Decimal string, e.g. "12345.60". Nil when the backend has no balance.
        public let balance: String?
        public let currencyCode: String
        /// Calendar date "yyyy-MM-dd" (UTC) of the last statement, or nil.
        public let lastStatementDate: String?
        public let daysSinceStatement: Int?
        public let status: String
        public let needsAction: Bool
    }

    public static func dataset(from statuses: [StatementStatus], generatedAt: Date) -> Dataset {
        Dataset(
            schemaVersion: schemaVersion,
            generatedAt: generatedAt,
            ledgers: statuses.map(record(from:))
        )
    }

    public static func jsonData(from statuses: [StatementStatus], generatedAt: Date) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(dataset(from: statuses, generatedAt: generatedAt))
    }

    public static let csvHeader = [
        "ledger_id", "display_name", "kind", "bank_name", "last4",
        "balance", "currency_code", "last_statement_date", "days_since_statement", "status", "needs_action"
    ]

    public static func csv(from statuses: [StatementStatus]) -> String {
        let rows = statuses.map(record(from:)).map(csvRow(for:))
        return ([csvRow(csvHeader)] + rows).joined(separator: "\n") + "\n"
    }

    static func record(from status: StatementStatus) -> Record {
        Record(
            ledgerId: status.ledgerId,
            displayName: status.displayName,
            kind: status.kind.rawValue,
            bankName: status.bankName,
            last4: status.last4,
            balance: status.balanceMinor.map(decimalString(minor:)),
            currencyCode: status.currencyCode,
            lastStatementDate: status.lastStatementDate.map(dateString(_:)),
            daysSinceStatement: status.daysSinceStatement,
            status: status.level.rawValue,
            needsAction: status.level.needsAction
        )
    }

    static func csvRow(for record: Record) -> String {
        csvRow([
            record.ledgerId, record.displayName, record.kind, record.bankName, record.last4,
            record.balance ?? "", record.currencyCode, record.lastStatementDate ?? "",
            record.daysSinceStatement.map(String.init) ?? "", record.status, record.needsAction ? "true" : "false"
        ])
    }

    static func csvRow(_ fields: [String]) -> String {
        fields.map(escapeCSV).joined(separator: ",")
    }

    static func escapeCSV(_ field: String) -> String {
        let needsQuoting = field.contains(",") || field.contains("\"") || field.contains("\n")
        guard needsQuoting else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    /// Minor units to decimal string assuming 2 fractional digits (INR paise, USD cents).
    static func decimalString(minor: Int64) -> String {
        let sign = minor < 0 ? "-" : ""
        let magnitude = minor.magnitude
        let whole = magnitude / 100
        let fraction = magnitude % 100
        let fractionText = fraction < 10 ? "0\(fraction)" : "\(fraction)"
        return "\(sign)\(whole).\(fractionText)"
    }

    static func dateString(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(pad(parts.year ?? 0, width: 4))-\(pad(parts.month ?? 0, width: 2))-\(pad(parts.day ?? 0, width: 2))"
    }

    static func pad(_ value: Int, width: Int) -> String {
        let text = String(value)
        return text.count >= width ? text : String(repeating: "0", count: width - text.count) + text
    }
}
