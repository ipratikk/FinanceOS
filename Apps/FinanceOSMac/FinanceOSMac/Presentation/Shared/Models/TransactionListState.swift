import FinanceCore
import Foundation
import Observation

@Observable
final class TransactionListState {
    var searchQuery: String = ""
    var typeFilter: TransactionType?
    var startDate: Date?
    var endDate: Date?

    var isFilterActive: Bool {
        typeFilter != nil || startDate != nil || endDate != nil
    }

    func sections(from rows: [TransactionRow]) -> [TransactionSection] {
        var filtered = rows

        if !searchQuery.isEmpty {
            filtered = filtered.filter { $0.title.localizedCaseInsensitiveContains(searchQuery) }
        }

        if let typeFilter {
            filtered = filtered.filter { $0.transactionType == typeFilter }
        }

        if let startDate {
            filtered = filtered.filter { $0.postedAt >= startDate }
        }

        if let endDate {
            let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: endDate) ?? endDate
            filtered = filtered.filter { $0.postedAt < nextDay }
        }

        let grouped = Dictionary(grouping: filtered) { row in
            let components = Calendar.current.dateComponents([.year, .month], from: row.postedAt)
            let year = components.year ?? 0
            let month = components.month ?? 0
            return String(format: "%04d-%02d", year, month)
        }

        let sections = grouped.map { key, rows in
            let date = dateFromMonthKey(key)
            let title = formatMonthTitle(date)
            let sortedRows = rows.sorted { $0.postedAt > $1.postedAt }
            return TransactionSection(id: key, title: title, rows: sortedRows)
        }

        return sections.sorted { $0.id > $1.id }
    }

    func reset() {
        searchQuery = ""
        typeFilter = nil
        startDate = nil
        endDate = nil
    }

    private func dateFromMonthKey(_ key: String) -> Date {
        let components = key.split(separator: "-").map { Int($0) ?? 0 }
        var dateComponents = DateComponents()
        dateComponents.year = components.count > 0 ? components[0] : Calendar.current.component(.year, from: Date())
        dateComponents.month = components.count > 1 ? components[1] : 1
        dateComponents.day = 1
        return Calendar.current.date(from: dateComponents) ?? Date()
    }

    private func formatMonthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}
