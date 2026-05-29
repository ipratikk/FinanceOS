import FinanceUI
import Foundation

enum DateRangeFilter: Equatable {
    case thisMonth
    case lastMonth
    case lastQuarter
    case lastSixMonths
    case financialYear(Int)
    case custom(from: Date?, endDate: Date?)

    var label: String {
        switch self {
        case .thisMonth: return "This Month"
        case .lastMonth: return "Last Month"
        case .lastQuarter: return "Last 3 Months"
        case .lastSixMonths: return "Last 6 Months"
        case let .financialYear(year):
            let start = String(year).suffix(2)
            let end = String(year + 1).suffix(2)
            return "FY\(start)-\(end)"
        case let .custom(from, endDate):
            let fmt = FormatterCache.shortDayMonth
            if let from, let endDate { return "\(fmt.string(from: from))–\(fmt.string(from: endDate))" }
            if let from { return "From \(fmt.string(from: from))" }
            if let endDate { return "Until \(fmt.string(from: endDate))" }
            return "Custom"
        }
    }

    var dateRange: (from: Date?, endDate: Date?) {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .thisMonth:
            let start = cal.date(from: cal.dateComponents([.year, .month], from: now))
            return (start, nil)
        case .lastMonth:
            guard let thisStart = cal.date(from: cal.dateComponents([.year, .month], from: now)),
                  let lastStart = cal.date(byAdding: .month, value: -1, to: thisStart) else {
                return (nil, nil)
            }
            let lastEnd = cal.date(byAdding: .day, value: -1, to: thisStart)
            return (lastStart, lastEnd)
        case .lastQuarter:
            return (cal.date(byAdding: .month, value: -3, to: now), nil)
        case .lastSixMonths:
            return (cal.date(byAdding: .month, value: -6, to: now), nil)
        case let .financialYear(year):
            var start = DateComponents(); start.year = year; start.month = 4; start.day = 1
            var end = DateComponents(); end.year = year + 1; end.month = 3; end.day = 31
            return (cal.date(from: start), cal.date(from: end))
        case let .custom(from, endDate):
            return (from, endDate)
        }
    }

    static var standardPresets: [DateRangeFilter] {
        [.thisMonth, .lastMonth, .lastQuarter, .lastSixMonths]
    }
}
