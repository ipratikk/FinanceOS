import FinanceCore
import Foundation
import Observation

@Observable
final class TransactionListState {
    var searchQuery: String = ""
    var typeFilter: TransactionType?
    var dateRangeFilter: DateRangeFilter?
    var availableFinancialYears: [Int] = []

    var isFilterActive: Bool {
        typeFilter != nil || dateRangeFilter != nil
    }

    func updateAvailableYears(from rows: [TransactionRow]) {
        let cal = Calendar.current
        let years = Set(rows.map { row -> Int in
            let month = cal.component(.month, from: row.postedAt)
            let year = cal.component(.year, from: row.postedAt)
            return month >= 4 ? year : year - 1
        })
        availableFinancialYears = years.sorted(by: >)
    }

    func sections(from rows: [TransactionRow]) -> [TransactionSection] {
        var filtered = rows

        if !searchQuery.isEmpty {
            filtered = filtered.filter { $0.title.localizedCaseInsensitiveContains(searchQuery) }
        }

        if let typeFilter {
            filtered = filtered.filter { $0.transactionType == typeFilter }
        }

        if let range = dateRangeFilter?.dateRange {
            if let from = range.from {
                filtered = filtered.filter { $0.postedAt >= from }
            }
            if let endDate = range.endDate {
                let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: endDate) ?? endDate
                filtered = filtered.filter { $0.postedAt < nextDay }
            }
        }

        let grouped = Dictionary(grouping: filtered) { row -> String in
            let comps = Calendar.current.dateComponents([.year, .month], from: row.postedAt)
            return String(format: "%04d-%02d", comps.year ?? 0, comps.month ?? 0)
        }

        let sections = grouped.map { key, rows in
            TransactionSection(
                id: key,
                title: formatMonthTitle(dateFromMonthKey(key)),
                rows: rows.sorted { $0.postedAt > $1.postedAt }
            )
        }
        return sections.sorted { $0.id > $1.id }
    }

    func reset() {
        searchQuery = ""
        typeFilter = nil
        dateRangeFilter = nil
    }

    private func dateFromMonthKey(_ key: String) -> Date {
        let parts = key.split(separator: "-").map { Int($0) ?? 0 }
        var comps = DateComponents()
        comps.year = parts.first ?? Calendar.current.component(.year, from: Date())
        comps.month = parts.count > 1 ? parts[1] : 1
        comps.day = 1
        return Calendar.current.date(from: comps) ?? Date()
    }

    private func formatMonthTitle(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: date)
    }
}
