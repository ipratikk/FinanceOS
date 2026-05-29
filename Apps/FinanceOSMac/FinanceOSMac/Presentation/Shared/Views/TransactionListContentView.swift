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
            TransactionSearchBar(searchQuery: $listState.searchQuery)
            TransactionFilterBar(listState: listState, showDatePopover: $showDatePopover)
            if sections.isEmpty { emptyState } else { transactionsList }
        }
        .background(AppColors.base)
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailView(row: transaction)
            // Note: onCorrected not wired here — account/card VMs don't have applyCorrection yet.
            // Corrections still persist via service.learn() and will be visible on next load.
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
            FDSLabel("This will permanently delete \"\(transactionPendingDelete?.title ?? "this transaction")\".")
        }
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
        FDSLabel(title)
            .font(AppTypography.labelMedium)
            .tracking(0.5)
            .foregroundStyle(.tertiary)
            .padding(.vertical, AppSpacing.compact)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.base.opacity(0.95))
    }

    private func sectionRowsContainer(_ rows: [TransactionRow]) -> some View {
        FDSCard {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    Button(action: { selectedTransaction = row }, label: {
                        FDSTransactionRow(
                            merchant: row.displayTitle,
                            categorySymbol: CategorySymbol.symbol(for: row.categoryId),
                            subtitle: row.subtitle,
                            amount: row.amountText,
                            isDebit: row.transactionType == .debit,
                            runningBalance: row.runningBalance
                        )
                    })
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
                .font(AppTypography.headingXLLight)
                .foregroundStyle(.tertiary)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: AppSpacing.tight) {
                FDSLabel("No Transactions")
                    .font(AppTypography.bodyLg)
                    .foregroundStyle(AppColors.Text.primary)
                FDSLabel(listState.isFilterActive ? "No transactions match your filters." : "No transactions found.")
                    .font(AppTypography.captionLg)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
