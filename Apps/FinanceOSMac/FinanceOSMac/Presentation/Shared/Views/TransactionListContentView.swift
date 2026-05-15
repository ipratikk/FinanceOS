import FinanceCore
import SwiftUI

struct TransactionListContentView: View {
    let sections: [TransactionSection]
    @Bindable var listState: TransactionListState
    @State private var showFilterSheet = false

    var body: some View {
        List {
            ForEach(sections) { section in
                Section(header: Text(section.title)) {
                    ForEach(section.rows) { row in
                        HStack(alignment: .top, spacing: 12) {
                            Image(
                                systemName: row.transactionType == .debit
                                    ? "arrow.up.left.circle.fill"
                                    : "arrow.down.right.circle.fill"
                            )
                            .font(.title3)
                            .foregroundColor(
                                row.transactionType == .debit ? .red : .green
                            )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.title)
                                    .lineLimit(1)
                                Text(row.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(row.amountText)
                                .font(.subheadline.monospacedDigit())
                                .foregroundColor(
                                    row.transactionType == .debit ? .red : .green
                                )
                        }
                    }
                }
            }

            if sections.isEmpty {
                ContentUnavailableView(
                    "No Transactions",
                    systemImage: "list.bullet",
                    description: Text(
                        listState.isFilterActive
                            ? "No transactions match your filters."
                            : "No transactions found."
                    )
                )
            }
        }
        .searchable(
            text: $listState.searchQuery,
            prompt: "Search transactions"
        )
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(
                    action: { showFilterSheet = true },
                    label: {
                        Image(systemName: listState.isFilterActive
                            ? "line.3.horizontal.decrease.circle.fill"
                            : "line.3.horizontal.decrease.circle"
                        )
                    }
                )
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            TransactionFilterView(listState: listState)
        }
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
