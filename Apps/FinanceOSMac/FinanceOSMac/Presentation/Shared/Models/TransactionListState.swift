import FinanceCore
import FinanceUI
import Foundation
import Observation

@Observable
final class TransactionListState {
    var searchQuery: String = ""
    var typeFilter: TransactionType?
    var categoryFilter: String?
    var dateRangeFilter: DateRangeFilter?
    var availableFinancialYears: [Int] = []

    private var debounceTask: Task<Void, Never>?

    var isFilterActive: Bool {
        typeFilter != nil || categoryFilter != nil || dateRangeFilter != nil
    }

    func setSearchQuery(_ query: String) {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            self.searchQuery = query
        }
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
            filtered = filtered.filter {
                $0.displayTitle.localizedCaseInsensitiveContains(searchQuery) ||
                    $0.subtitle.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        if let typeFilter {
            filtered = filtered.filter { $0.transactionType == typeFilter }
        }

        if let cat = categoryFilter {
            filtered = filtered.filter { $0.categoryId == cat }
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

        let cal = Calendar.current
        let grouped = Dictionary(grouping: filtered) { cal.startOfDay(for: $0.postedAt) }

        return grouped.map { dayStart, dayRows in
            let sorted = dayRows.sorted { $0.postedAt > $1.postedAt }
            let net = sorted.reduce(Int64(0)) { sum, row in
                sum + (row.transactionType == .debit ? -row.amountMinorUnits : row.amountMinorUnits)
            }
            let comps = cal.dateComponents([.year, .month, .day], from: dayStart)
            let id = String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
            return TransactionSection(
                id: id,
                title: FormatterCache.fullDayDate.string(from: dayStart).uppercased(),
                date: dayStart,
                rows: sorted,
                netAmountMinorUnits: net
            )
        }
        .sorted { $0.date > $1.date }
    }

    func reset() {
        searchQuery = ""
        typeFilter = nil
        categoryFilter = nil
        dateRangeFilter = nil
    }
}
