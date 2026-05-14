import FinanceCore
import SwiftUI

struct TransactionFilterView: View {
    @Bindable var listState: TransactionListState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Transaction Type", selection: $listState.typeFilter) {
                        Text("All").tag(TransactionType?.none)
                        Text("Debit").tag(TransactionType?.some(.debit))
                        Text("Credit").tag(TransactionType?.some(.credit))
                    }
                }

                Section("Date Range") {
                    DatePicker(
                        "From",
                        selection: Binding(
                            get: { listState.startDate ?? Date() },
                            set: { listState.startDate = $0 }
                        ),
                        displayedComponents: [.date]
                    )
                    if listState.startDate != nil {
                        Button("Clear Start Date") {
                            listState.startDate = nil
                        }
                    }

                    DatePicker(
                        "To",
                        selection: Binding(
                            get: { listState.endDate ?? Date() },
                            set: { listState.endDate = $0 }
                        ),
                        displayedComponents: [.date]
                    )
                    if listState.endDate != nil {
                        Button("Clear End Date") {
                            listState.endDate = nil
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        listState.reset()
                    } label: {
                        Label("Reset Filters", systemImage: "arrow.clockwise")
                    }
                }
            }
            .navigationTitle("Filter Transactions")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TransactionFilterView(listState: TransactionListState())
}
