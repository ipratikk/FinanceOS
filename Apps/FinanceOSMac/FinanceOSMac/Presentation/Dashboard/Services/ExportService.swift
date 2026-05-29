import FinanceCore
import FinanceUI
import Foundation

protocol ExportServiceProtocol: Sendable {
    func netWorthCSV(series: [NetWorthPoint]) -> String
}

struct ExportService: ExportServiceProtocol {
    func netWorthCSV(series: [NetWorthPoint]) -> String {
        let header = "Date,NetWorth"
        let rows = series.map { "\(FormatterCache.iso8601.string(from: $0.timestamp)),\($0.netWorth)" }
        return ([header] + rows).joined(separator: "\n")
    }
}
