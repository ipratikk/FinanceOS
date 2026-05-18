import FinanceCore
import FinanceUI
import SwiftUI

struct TransactionListContentView: View {
    let sections: [TransactionSection]
    @Bindable var listState: TransactionListState
    var onDelete: ((UUID) -> Void)?

    @State private var transactionPendingDelete: TransactionRow?
    @State private var selectedTransaction: TransactionRow?
    @State private var showDatePopover = false

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            filterChipRow
            if sections.isEmpty { emptyState } else { transactionsList }
        }
        .background(AppColors.base)
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailView(row: transaction)
        }
        .alert(
            "Delete Transaction?",
            isPresented: Binding(
                get: { transactionPendingDelete != nil },
                set: { if !$0 { transactionPendingDelete = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { transactionPendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let row = transactionPendingDelete {
                    transactionPendingDelete = nil
                    onDelete?(row.id)
                }
            }
        } message: {
            Text("This will permanently delete \"\(transactionPendingDelete?.title ?? "this transaction")\".")
        }
    }

    private var searchBar: some View {
        HStack(spacing: AppSpacing.compact) {
            HStack(spacing: AppSpacing.compact) {
                Image(systemName: "magnifyingglass")
                    .font(AppTypography.captionLgSemibold)
                    .foregroundStyle(.tertiary)

                TextField("Search transactions", text: $listState.searchQuery)
                    .font(AppTypography.bodySm)
                    .textFieldStyle(.plain)

                if !listState.searchQuery.isEmpty {
                    Button(action: { listState.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(AppTypography.captionLg)
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.compact)
            .padding(.vertical, 6)
            .background { Capsule(style: .continuous).fill(.ultraThinMaterial) }
            .overlay { Capsule(style: .continuous).strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5) }
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.compact)
    }

    private var filterChipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.compact) {
                typeChip(label: "Debit", type: .debit)
                typeChip(label: "Credit", type: .credit)

                Divider()
                    .frame(height: 16)
                    .opacity(0.3)

                dateChip

                if listState.isFilterActive {
                    Button(action: { listState.reset() }) {
                        HStack(spacing: 3) {
                            Image(systemName: "xmark.circle.fill")
                                .font(AppTypography.label)
                            Text("Clear")
                                .font(AppTypography.captionLgMedium)
                        }
                        .foregroundStyle(AppColors.accent)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.compact)
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: listState.isFilterActive)
    }

    private func typeChip(label: String, type: TransactionType) -> some View {
        let active = listState.typeFilter == type
        return Button {
            listState.typeFilter = active ? nil : type
        } label: {
            Text(label)
                .font(active ? AppTypography.captionLgSemibold : AppTypography.captionLg)
                .foregroundStyle(active ? AppColors.accent : Color.secondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 5)
                .background {
                    Capsule(style: .continuous)
                        .fill(active ? AppColors.accent.opacity(0.15) : Color.clear)
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(
                                    active ? AppColors.accent.opacity(0.5) : Color.secondary.opacity(0.2),
                                    lineWidth: 0.5
                                )
                        )
                }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: active)
    }

    private var dateChip: some View {
        let active = listState.dateRangeFilter != nil
        return Button {
            showDatePopover = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(AppTypography.captionSmMedium)
                Text(listState.dateRangeFilter?.label ?? "Date")
                    .font(active ? AppTypography.captionLgSemibold : AppTypography.captionLg)
                if !active {
                    Image(systemName: "chevron.down")
                        .font(AppTypography.iconSm)
                }
            }
            .foregroundStyle(active ? AppColors.accent : Color.secondary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 5)
            .background {
                Capsule(style: .continuous)
                    .fill(active ? AppColors.accent.opacity(0.15) : Color.clear)
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(
                                active ? AppColors.accent.opacity(0.5) : Color.secondary.opacity(0.2),
                                lineWidth: 0.5
                            )
                    )
            }
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showDatePopover, arrowEdge: .bottom) {
            DateFilterPopover(listState: listState, isPresented: $showDatePopover)
        }
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: active)
    }

    private var transactionsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: AppSpacing.xl, pinnedViews: [.sectionHeaders]) {
                ForEach(sections) { section in
                    Section {
                        sectionRowsContainer(section.rows)
                    } header: {
                        sectionHeader(section.title)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .labelSmall()
            .tracking(0.6)
            .foregroundStyle(.tertiary)
            .padding(.vertical, AppSpacing.compact)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.base.opacity(0.95))
    }

    private func sectionRowsContainer(_ rows: [TransactionRow]) -> some View {
        FDSCard {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    Button(action: { selectedTransaction = row }) {
                        FDSTransactionRow(
                            merchant: row.title,
                            categorySymbol: nil,
                            subtitle: row.subtitle,
                            amount: row.amountText,
                            isDebit: row.transactionType == .debit,
                            runningBalance: row.runningBalance
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Delete", role: .destructive) { transactionPendingDelete = row }
                    }

                    if index < rows.count - 1 {
                        Divider().opacity(0.3).padding(.leading, 64)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "list.bullet")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.tertiary)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: AppSpacing.tight) {
                Text("No Transactions").bodyLarge()
                Text(listState.isFilterActive ? "No transactions match your filters." : "No transactions found.")
                    .font(AppTypography.captionLg)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DateFilterPopover: View {
    @Bindable var listState: TransactionListState
    @Binding var isPresented: Bool

    @State private var customFrom: Date = Date()
    @State private var customTo: Date = Date()

    private var isCustom: Bool {
        if case .custom = listState.dateRangeFilter { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("DATE RANGE")
                .font(AppTypography.labelSemibold)
                .tracking(0.6)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.compact)

            ForEach(DateRangeFilter.standardPresets, id: \.label) { preset in
                presetRow(preset)
            }

            if !listState.availableFinancialYears.isEmpty {
                Divider().opacity(0.3).padding(.vertical, 4)
                ForEach(listState.availableFinancialYears, id: \.self) { year in
                    presetRow(.financialYear(year))
                }
            }

            Divider().opacity(0.3).padding(.vertical, 4)

            customRow

            if isCustom {
                customDatePickers
            }

            Spacer(minLength: 0)
        }
        .frame(width: 220)
        .padding(.bottom, AppSpacing.md)
        .background(AppColors.base)
        .onAppear {
            if case let .custom(from, endDate) = listState.dateRangeFilter {
                if let from { customFrom = from }
                if let endDate { customTo = endDate }
            }
        }
    }

    private func presetRow(_ preset: DateRangeFilter) -> some View {
        let active = listState.dateRangeFilter == preset
        return Button {
            listState.dateRangeFilter = active ? nil : preset
            if !isCustom { isPresented = false }
        } label: {
            HStack {
                Text(preset.label)
                    .font(active ? AppTypography.bodySmSemibold : AppTypography.bodySm)
                    .foregroundStyle(active ? AppColors.accent : Color.primary)
                Spacer()
                if active {
                    Image(systemName: "checkmark")
                        .font(AppTypography.captionSmSemibold)
                        .foregroundStyle(AppColors.accent)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var customRow: some View {
        let active = isCustom
        return Button {
            if active {
                listState.dateRangeFilter = nil
            } else {
                listState.dateRangeFilter = .custom(from: nil, endDate: nil)
            }
        } label: {
            HStack {
                Text("Custom")
                    .font(active ? AppTypography.bodySmSemibold : AppTypography.bodySm)
                    .foregroundStyle(active ? AppColors.accent : Color.primary)
                Spacer()
                Image(systemName: active ? "checkmark" : "chevron.right")
                    .font(AppTypography.captionSmSemibold)
                    .foregroundStyle(active ? AppColors.accent : Color.secondary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var customDatePickers: some View {
        VStack(alignment: .leading, spacing: AppSpacing.compact) {
            customDateRow(label: "From", date: Binding(
                get: { customFrom },
                set: { customFrom = $0; listState.dateRangeFilter = .custom(from: $0, endDate: customTo) }
            ))
            customDateRow(label: "To", date: Binding(
                get: { customTo },
                set: { customTo = $0; listState.dateRangeFilter = .custom(from: customFrom, endDate: $0) }
            ))
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.compact)
        .background(AppColors.accent.opacity(0.05))
    }

    private func customDateRow(label: String, date: Binding<Date>) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.captionLgMedium)
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .leading)
            DatePicker("", selection: date, displayedComponents: [.date])
                .labelsHidden()
                .controlSize(.small)
        }
    }
}
