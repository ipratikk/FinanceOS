import FinanceCore
import SwiftUI

struct BankEditView: View {
    let bank: Bank
    let viewModel: BanksViewModel
    @State private var name: String
    @State private var providerType: BankProviderType
    @Environment(\.dismiss) var dismiss

    @State private var showDeleteConfirm = false

    init(bank: Bank, viewModel: BanksViewModel) {
        self.bank = bank
        self.viewModel = viewModel
        _name = State(initialValue: bank.name)
        _providerType = State(initialValue: bank.providerType)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Bank Details") {
                    TextField("Name", text: $name)
                    Picker("Provider Type", selection: $providerType) {
                        ForEach(BankProviderType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                }

                Section {
                    Button("Delete Bank", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
            .navigationTitle("Edit Bank")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        Task {
                            let updated = Bank(
                                id: bank.id,
                                name: name,
                                providerType: providerType
                            )
                            await viewModel.updateBank(updated)
                        }
                    }
                }
            }
        }
        .alert("Delete Bank?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteBank(id: bank.id)
                    dismiss()
                }
            }
        } message: {
            let deleteMsg = "This will permanently delete this bank and all " +
                "associated cards, accounts, and transactions. " +
                "This cannot be undone."
            Text(deleteMsg)
        }
    }
}
