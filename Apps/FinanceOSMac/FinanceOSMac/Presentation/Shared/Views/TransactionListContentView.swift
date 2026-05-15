import FinanceCore
import SwiftUI

struct TransactionListContentView: View {
    let sections: [TransactionSection]
    @Bindable var listState: TransactionListState
    @State private var showFilterSheet = false

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
                                .font(.system(size: 12))
                            Text("Clear filters")
                                .font(.system(size: 12, weight: .medium))
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
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {} label: {
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
                .fill(row.transactionType == .debit ? Color.red : Color.green)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)

                Text(row.subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppColors.textTertiary)
            }

            Spacer()

            HStack(spacing: 8) {
                Text(row.amountText)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(row.transactionType == .debit ? .red : .green)

                Text(row.transactionType == .debit ? "Dr" : "Cr")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.vertical, 2)
                    .padding(.horizontal, 6)
                    .background(row.transactionType == .debit ? Color.red
                        .opacity(0.15) : Color.green.opacity(0.15))
                    .foregroundColor(row.transactionType == .debit ? .red : .green)
                    .cornerRadius(AppRadius.sm)
            }
        }
        .padding(AppSpacing.sm)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(AppColors.textTertiary)

            VStack(spacing: 8) {
                Text("No Transactions")
                    .font(.system(size: 16, weight: .semibold))

                Text(
                    listState.isFilterActive
                        ? "No transactions match your filters."
                        : "No transactions found."
                )
                .font(.system(size: 13, weight: .regular))
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
