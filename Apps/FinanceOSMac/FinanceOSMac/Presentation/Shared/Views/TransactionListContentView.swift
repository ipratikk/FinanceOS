import FinanceCore
import FinanceUI
import SwiftUI

struct TransactionListContentView: View {
    let sections: [TransactionSection]
    @Bindable var listState: TransactionListState
    var onDelete: ((UUID) -> Void)?
    @State private var showFilterSheet = false
    @State private var transactionPendingDelete: TransactionRow?
    @State private var selectedTransaction: TransactionRow?

    var body: some View {
        VStack(spacing: 0) {
            searchAndFilterBar

            if sections.isEmpty {
                emptyState
            } else {
                transactionsList
            }
        }
        .background(AppColors.base)
        .sheet(isPresented: $showFilterSheet) {
            TransactionFilterView(listState: listState)
        }
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
            Text(
                "This will permanently delete \"\(transactionPendingDelete?.title ?? "this transaction")\"."
            )
        }
    }

    private var searchAndFilterBar: some View {
        HStack(spacing: AppSpacing.compact) {
            HStack(spacing: AppSpacing.compact) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)

                TextField("Search transactions", text: $listState.searchQuery)
                    .font(.system(size: 13))
                    .textFieldStyle(.plain)

                if !listState.searchQuery.isEmpty {
                    Button(action: { listState.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.compact)
            .padding(.vertical, 6)
            .background {
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
            }

            if listState.isFilterActive {
                Button(action: { listState.reset() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Clear")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.accent)
                }
                .buttonStyle(.plain)
            }

            Button { showFilterSheet = true } label: {
                Image(systemName: listState.isFilterActive
                    ? "line.3.horizontal.decrease.circle.fill"
                    : "line.3.horizontal.decrease.circle"
                )
                .bodyMedium()
                .foregroundStyle(listState.isFilterActive ? AppColors.accent : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.vertical, AppSpacing.md)
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
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                Button(action: { selectedTransaction = row }) {
                    FDSTransactionRow(
                        merchant: row.title,
                        categorySymbol: nil,
                        subtitle: row.subtitle,
                        amount: row.amountText,
                        isDebit: row.transactionType == .debit
                    )
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Delete", role: .destructive) {
                        transactionPendingDelete = row
                    }
                }

                if index < rows.count - 1 {
                    Divider()
                        .opacity(0.3)
                        .padding(.leading, 64)
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.05), lineWidth: 0.5)
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
                Text("No Transactions")
                    .bodyLarge()
                Text(
                    listState.isFilterActive
                        ? "No transactions match your filters."
                        : "No transactions found."
                )
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
