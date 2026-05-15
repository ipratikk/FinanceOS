import FinanceCore
import SwiftUI

struct TransactionListContentView: View {
    let sections: [TransactionSection]
    @Bindable var listState: TransactionListState
    @State private var showFilterSheet = false
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))

                    TextField("Search transactions", text: $listState.searchQuery)
                        .textFieldStyle(.plain)

                    if !listState.searchQuery.isEmpty {
                        Button(action: { listState.searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))
                        }
                    }
                }
                .padding(8)
                .background(Color(red: 0.110, green: 0.110, blue: 0.122))
                .cornerRadius(10)

                HStack(spacing: 8) {
                    if listState.isFilterActive {
                        Button(action: { listState.reset() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                Text("Clear filters")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color(red: 0.231, green: 0.510, blue: 0.980).opacity(0.2))
                            .cornerRadius(6)
                        }
                    }

                    Spacer()

                    Button(action: { showFilterSheet = true }) {
                        Image(systemName: listState.isFilterActive
                            ? "line.3.horizontal.decrease.circle.fill"
                            : "line.3.horizontal.decrease.circle"
                        )
                    }
                }
            }
            .padding(16)
            .background(Color(red: 0.051, green: 0.051, blue: 0.059))

            if sections.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))

                    VStack(spacing: 8) {
                        Text("No Transactions")
                            .font(.system(size: 16, weight: .semibold))

                        Text(
                            listState.isFilterActive
                                ? "No transactions match your filters."
                                : "No transactions found."
                        )
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(sections) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(section.title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))

                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 8)

                                VStack(spacing: 8) {
                                    ForEach(section.rows) { row in
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
                                                    .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))
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
                                                    .background(row.transactionType == .debit ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                                                    .foregroundColor(row.transactionType == .debit ? .red : .green)
                                                    .cornerRadius(4)
                                            }
                                        }
                                        .padding(12)
                                        .background(Color(red: 0.086, green: 0.086, blue: 0.098))
                                        .cornerRadius(10)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(Color(red: 0.051, green: 0.051, blue: 0.059))
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
