import FinanceCore
import SwiftUI

struct CreateNewTargetSheet: View {
    @Binding var name: String
    @Binding var nickname: String
    @Binding var last4: String
    @Binding var bankID: UUID?
    let isCard: Bool
    let banks: [Bank]
    let detectedBank: String
    let onCancel: () -> Void
    let onCreate: () -> Void

    var selectedBank: Bank? {
        guard let id = bankID else { return nil }
        return banks.first { $0.id == id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name (optional)", text: $name)
                }

                Section("Bank") {
                    if let bank = selectedBank {
                        Text(bank.name)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(detectedBank)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(isCard ? "Card Details" : "Account Details") {
                    if isCard {
                        TextField("Nickname", text: $nickname)
                    }
                    TextField("Last 4 Digits", text: $last4)
                        .onChange(of: last4) { _, newValue in
                            if newValue.count > 4 {
                                last4 = String(newValue.prefix(4))
                            }
                        }
                }

                if !banks.isEmpty {
                    Section(selectedBank == nil ? "Select Bank" : "Change Bank") {
                        Picker("Bank", selection: $bankID) {
                            Text("Select Bank").tag(UUID?.none)
                            ForEach(banks) { bank in
                                Text(bank.name).tag(UUID?(bank.id))
                            }
                        }
                    }
                }
            }
            .navigationTitle(isCard ? "Create New Card" : "Create New Account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate()
                    }
                    .disabled(last4.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
