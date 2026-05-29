import FinanceCore
import FinanceIntelligence
import FinanceUI
import SwiftUI

struct TransactionsView: View {
    @State private var viewModel: TransactionsViewModel
    @State private var listState = TransactionListState()
    @State private var showDatePopover = false
    @State private var showCategoryPopover = false
    @State private var selectedTransaction: TransactionRow?
    @State private var transactionPendingDelete: TransactionRow?
    @State private var searchDebounceTask: Task<Void, Never>?

    init(viewModel: TransactionsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading, viewModel.transactionRows.isEmpty {
                FDSEmptyState(symbol: "arrow.clockwise", title: "Loading transactions…", subtitle: "")
            } else if viewModel.transactionRows.isEmpty {
                FDSEmptyState(
                    symbol: "creditcard",
                    title: "No Transactions",
                    subtitle: "Import a bank statement to get started."
                )
            } else {
                searchAndFilterBar
                transactionsList
            }
        }
        .background(AppColors.base)
        .navigationTitle("Transactions")
        .searchable(
            text: Binding(
                get: { listState.searchQuery },
                set: { newValue in
                    searchDebounceTask?.cancel()
                    searchDebounceTask = Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(150))
                        listState.searchQuery = newValue
                    }
                }
            ),
            placement: .toolbar,
            prompt: "Search merchant, category…"
        )
        .task { await viewModel.loadTransactions() }
        .sheet(item: $selectedTransaction) { row in
            TransactionDetailView(row: row, onCorrected: { id, catId in
                Task { await viewModel.applyCorrection(transactionId: id, correctedCategoryId: catId) }
            })
        }
        .alert("Delete Transaction?", isPresented: Binding(
            get: { transactionPendingDelete != nil },
            set: { if !$0 { transactionPendingDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { transactionPendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let row = transactionPendingDelete {
                    transactionPendingDelete = nil
                    Task { await viewModel.deleteTransaction(id: row.id) }
                }
            }
        } message: {
            if let row = transactionPendingDelete {
                Text("Permanently delete \"\(row.displayTitle)\"?")
            }
        }
        .alert("Delete Failed", isPresented: Binding(
            get: { viewModel.deleteError != nil },
            set: { if !$0 { viewModel.deleteError = nil } }
        )) {
            Button("OK") { viewModel.deleteError = nil }
        } message: {
            if let error = viewModel.deleteError { Text(error) }
        }
    }
}

// MARK: - Computed data

private extension TransactionsView {
    var filteredRows: [TransactionRow] {
        var rows = viewModel.transactionRows
        if !listState.searchQuery.isEmpty {
            rows = rows.filter {
                $0.displayTitle.localizedCaseInsensitiveContains(listState.searchQuery) ||
                    $0.subtitle.localizedCaseInsensitiveContains(listState.searchQuery)
            }
        }
        if let type = listState.typeFilter { rows = rows.filter { $0.transactionType == type } }
        if let cat = listState.categoryFilter { rows = rows.filter { $0.categoryId == cat } }
        if let range = listState.dateRangeFilter?.dateRange {
            if let from = range.from { rows = rows.filter { $0.postedAt >= from } }
            if let end = range.endDate {
                let next = Calendar.current.date(byAdding: .day, value: 1, to: end) ?? end
                rows = rows.filter { $0.postedAt < next }
            }
        }
        return rows
    }

    var daySections: [(date: Date, rows: [TransactionRow])] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: filteredRows) { cal.startOfDay(for: $0.postedAt) }
        return grouped.map { ($0.key, $0.value.sorted { $0.postedAt > $1.postedAt }) }
            .sorted { $0.date > $1.date }
    }
}

// MARK: - Filter bar

private extension TransactionsView {
    var searchAndFilterBar: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.compact) {
                    FDSChip("Debits", isActive: listState.typeFilter == .debit, tone: .debit) {
                        listState.typeFilter = listState.typeFilter == .debit ? nil : .debit
                    }
                    FDSChip("Credits", isActive: listState.typeFilter == .credit, tone: .credit) {
                        listState.typeFilter = listState.typeFilter == .credit ? nil : .credit
                    }
                    categoryChip
                    dateChip
                    if listState.isFilterActive {
                        Button(action: { listState.reset() }) {
                            HStack(spacing: 3) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(AppTypography.captionSm)
                                FDSLabel("Clear").font(AppTypography.captionLgMedium)
                            }
                            .foregroundStyle(AppColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, AppSpacing.compact)
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: listState.isFilterActive)
            Divider().opacity(0.08)
        }
    }

    var categoryChip: some View {
        let active = listState.categoryFilter != nil
        let label = listState.categoryFilter.flatMap {
            CategoryTaxonomy.current.category(forId: $0)?.displayName
        } ?? "Category"
        return Button { showCategoryPopover = true } label: {
            HStack(spacing: 4) {
                Image(systemName: "tag").font(AppTypography.captionSmSemibold)
                FDSLabel(label)
                    .font(active ? AppTypography.captionLgSemibold : AppTypography.captionLg)
                if !active { Image(systemName: "chevron.down").font(AppTypography.captionSm) }
            }
            .foregroundStyle(active ? AppColors.accentPurple : AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.compact)
            .background {
                Capsule()
                    .fill(active ? AppColors.accentPurple.opacity(0.12) : AppColors.surface2)
                    .overlay(Capsule().strokeBorder(
                        active ? AppColors.accentPurple.opacity(0.2) : AppColors.border,
                        lineWidth: 0.5
                    ))
            }
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showCategoryPopover, arrowEdge: .bottom) {
            CategoryFilterPopover(
                selectedCategoryId: Binding(
                    get: { listState.categoryFilter },
                    set: { listState.categoryFilter = $0; showCategoryPopover = false }
                )
            )
        }
    }

    var dateChip: some View {
        let active = listState.dateRangeFilter != nil
        return Button { showDatePopover = true } label: {
            HStack(spacing: 4) {
                Image(systemName: "calendar").font(AppTypography.captionSmSemibold)
                FDSLabel(listState.dateRangeFilter?.label ?? "Date")
                    .font(active ? AppTypography.captionLgSemibold : AppTypography.captionLg)
                if !active { Image(systemName: "chevron.down").font(AppTypography.captionSm) }
            }
            .foregroundStyle(active ? AppColors.accent : AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.compact)
            .background {
                Capsule()
                    .fill(active ? AppColors.accent.opacity(0.12) : AppColors.surface2)
                    .overlay(Capsule().strokeBorder(
                        active ? AppColors.accent.opacity(0.2) : AppColors.border,
                        lineWidth: 0.5
                    ))
            }
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showDatePopover, arrowEdge: .bottom) {
            DateFilterPopover(listState: listState, isPresented: $showDatePopover)
        }
    }
}

// MARK: - Transaction list

private extension TransactionsView {
    @ViewBuilder var transactionsList: some View {
        if daySections.isEmpty {
            FDSEmptyState(
                symbol: "line.3.horizontal.decrease.circle",
                title: "No results",
                subtitle: "Try adjusting your filters."
            )
        } else {
            listContent
        }
    }

    private var listContent: some View {
        List {
            ForEach(daySections, id: \.date) { date, rows in
                Section {
                    ForEach(rows) { row in
                        Button { selectedTransaction = row } label: {
                            transactionRow(row)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(AppColors.surface)
                        .listRowSeparatorTint(AppColors.border.opacity(0.5))
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                transactionPendingDelete = row
                            }
                        }
                    }
                } header: {
                    dayHeader(date: date, rows: rows)
                }
            }
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 0)
    }

    func dayHeader(date: Date, rows: [TransactionRow]) -> some View {
        let dayNet = rows.reduce(Int64(0)) { sum, row in
            sum + (row.transactionType == .debit ? -row.amountMinorUnits : row.amountMinorUnits)
        }
        return HStack {
            FDSLabel(FormatterCache.fullDayDate.string(from: date).uppercased())
                .font(AppTypography.captionSmSemibold)
                .tracking(0.4)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            HStack(spacing: 4) {
                FDSLabel("\(rows.count) txn\(rows.count == 1 ? "" : "s")")
                    .font(AppTypography.captionSm)
                    .foregroundStyle(.tertiary)
                FDSLabel("·").font(AppTypography.captionSm).foregroundStyle(.tertiary)
                FDSAmount(
                    FormatterCache.formatCurrency(minorUnits: abs(dayNet)),
                    type: dayNet < 0 ? .debit : .credit,
                    size: .small
                )
            }
        }
        .padding(.top, AppSpacing.xl)
        .padding(.bottom, AppSpacing.compact)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .background(AppColors.base)
    }

    func transactionRow(_ row: TransactionRow) -> some View {
        HStack(spacing: AppSpacing.md) {
            FDSCategoryGlyph(
                row.categoryId ?? "other",
                icon: CategorySymbol.symbol(for: row.categoryId),
                size: 36
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    FDSLabel(row.displayTitle)
                        .font(AppTypography.bodySmMedium)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                    if let catId = row.categoryId {
                        categoryBadge(catId)
                    }
                }
                FDSLabel(row.subtitle)
                    .font(AppTypography.captionLg)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: AppSpacing.md)

            VStack(alignment: .trailing, spacing: 3) {
                FDSAmount(row.amountText, type: row.transactionType == .debit ? .debit : .credit)
                if row.isUserCorrected {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(AppTypography.captionSm)
                            .foregroundStyle(AppColors.accent.opacity(0.8))
                        FDSLabel("Corrected")
                            .font(AppTypography.captionSm)
                            .foregroundStyle(AppColors.accent.opacity(0.7))
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, AppSpacing.md)
    }

    // TODO: FDS candidate — display-only category label chip
    func categoryBadge(_ categoryId: String) -> some View {
        let label = CategoryTaxonomy.current.category(forId: categoryId)?.displayName
            ?? categoryId.capitalized
        let color = CategorySymbol.color(for: categoryId)
        return FDSLabel(label.uppercased())
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}
