import FinanceCore
import FinanceUI
import Foundation

protocol ExportServiceProtocol: Sendable {
    func netWorthCSV(series: [NetWorthPoint]) -> String
}

struct ExportService: ExportServiceProtocol {
    func netWorthCSV(series: [NetWorthPoint]) -> String {
        let header = "Date,NetWorth"
        let rows = series.map {
            let netWorthRupees = Decimal($0.netWorthMinorUnits) / 100
            return "\(FormatterCache.iso8601.string(from: $0.timestamp)),\(netWorthRupees)"
        }
        return ([header] + rows).joined(separator: "\n")
    }
}
