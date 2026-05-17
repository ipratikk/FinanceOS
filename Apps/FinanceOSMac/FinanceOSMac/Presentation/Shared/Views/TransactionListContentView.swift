import FinanceCore
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
                "This will permanently delete \"\(transactionPendingDelete?.title ?? "this transaction")\". This cannot be undone."
            )
        }
    }

    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textTertiary)

                TextField("Search transactions", text: $listState.searchQuery)
                    .textFieldStyle(.plain)

                if !listState.searchQuery.isEmpty {
                    Button(action: { listState.searchQuery = "" }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.textTertiary)
                    })
                }
            }
            .padding(AppSpacing.xs)
            .background(AppColors.surface2)
            .cornerRadius(AppRadius.md)

            HStack(spacing: 8) {
                if listState.isFilterActive {
                    Button(action: { listState.reset() }, label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .labelSmall()
                            Text("Clear filters")
                                .labelSmall()
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(AppColors.accent.opacity(0.2))
                        .cornerRadius(AppRadius.sm)
                    })
                }

                Spacer()

                Button {
                    showFilterSheet = true
                } label: {
                    Image(systemName: listState.isFilterActive
                        ? "line.3.horizontal.decrease.circle.fill"
                        : "line.3.horizontal.decrease.circle"
                    )
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.base)
    }

    private var transactionsList: some View {
        List {
            ForEach(sections) { section in
                Section(section.title) {
                    ForEach(section.rows) { row in
                        transactionRow(row)
                            .listRowBackground(AppColors.surface)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    transactionPendingDelete = row
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(AppColors.base)
        .scrollContentBackground(.hidden)
    }

    private func transactionRow(_ row: TransactionRow) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(row.transactionType == .debit ? AppColors.debit : AppColors.credit)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .bodyLarge()
                    .lineLimit(1)

                Text(row.subtitle)
                    .labelSmall()
                    .foregroundColor(AppColors.textTertiary)
            }

            Spacer()

            HStack(spacing: 8) {
                Text(row.amountText)
                    .monoAmount()
                    .foregroundColor(row.transactionType == .debit ? AppColors.debit : AppColors.credit)

                Text(row.transactionType == .debit ? "Dr" : "Cr")
                    .labelSmall()
                    .padding(.vertical, 2)
                    .padding(.horizontal, 6)
                    .background(row.transactionType == .debit ? AppColors.debit
                        .opacity(0.15) : AppColors.credit.opacity(0.15))
                    .foregroundColor(row.transactionType == .debit ? AppColors.debit : AppColors.credit)
                    .cornerRadius(AppRadius.sm)
            }
        }
        .padding(AppSpacing.sm)
        .onTapGesture {
            selectedTransaction = row
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(AppColors.textTertiary)

            VStack(spacing: 8) {
                Text("No Transactions")
                    .headingSmall()

                Text(
                    listState.isFilterActive
                        ? "No transactions match your filters."
                        : "No transactions found."
                )
                .caption()
                .foregroundColor(AppColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

#Preview {
    let state = TransactionListState()
    let section = TransactionSection(
        id: "2026-05",
        title: "May 2026",
        rows: [
            TransactionRow(
                id: UUID(),
                title: "Coffee",
                subtitle: "Checking",
                amountText: "-USD 5.00",
                transactionType: .debit,
                postedAt: Date()
            ),
            TransactionRow(
                id: UUID(),
                title: "Salary",
                subtitle: "Checking",
                amountText: "+USD 5000.00",
                transactionType: .credit,
                postedAt: Date()
            )
        ]
    )

    TransactionListContentView(
        sections: [section],
        listState: state
    )
}
