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
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Edit Bank")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Button(action: { dismiss() }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                })
            }
            .padding(16)
            .background(Color(red: 0.051, green: 0.051, blue: 0.059))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bank Information")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)

                        VStack(spacing: 8) {
                            inputField("Name", text: $name)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Provider Type")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                                Picker("Type", selection: $providerType) {
                                    ForEach(BankProviderType.allCases, id: \.self) { type in
                                        Text(type.rawValue.capitalized).tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(10)
                            .background(Color(red: 0.110, green: 0.110, blue: 0.122))
                            .cornerRadius(6)
                        }
                    }
                    .padding(12)
                    .background(Color(red: 0.086, green: 0.086, blue: 0.098))
                    .cornerRadius(10)

                    VStack(spacing: 8) {
                        Button(action: { showDeleteConfirm = true }, label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 12))
                                Text("Delete Bank")
                                    .font(.system(size: 14, weight: .medium))
                                Spacer()
                            }
                        })
                        .foregroundColor(.red)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(16)
            }

            Divider()

            HStack(spacing: 12) {
                Button("Cancel", action: { dismiss() })
                    .foregroundColor(.gray)
                    .padding(12)
                    .background(Color(red: 0.086, green: 0.086, blue: 0.098))
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)

                Button(action: {
                    Task {
                        let updated = Bank(
                            id: bank.id,
                            name: name,
                            providerType: providerType
                        )
                        await viewModel.updateBank(updated)
                        dismiss()
                    }
                }, label: {
                    Text("Save")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                })
                .padding(12)
                .background(Color(red: 0.231, green: 0.510, blue: 0.980))
                .cornerRadius(8)
            }
            .padding(16)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.051, green: 0.051, blue: 0.059))
        .alert("Delete Bank?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteBank(id: bank.id)
                    dismiss()
                }
            }
        } message: {
            Text("This will delete this bank and all associated cards, " +
                "accounts, and transactions. This cannot be undone.")
        }
    }

    private func inputField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.gray)
            TextField("", text: text)
                .font(.system(size: 13, weight: .regular))
                .padding(10)
                .background(Color(red: 0.110, green: 0.110, blue: 0.122))
                .cornerRadius(6)
        }
    }
}
