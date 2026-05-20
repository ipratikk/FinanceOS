import FinanceCore
import FinanceUI
import SwiftUI

struct BankEditView: View {
    let bank: Bank
    let context: BankEditContext
    @State private var name: String
    @State private var providerType: String
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirm = false

    init(bank: Bank, context: BankEditContext) {
        self.bank = bank
        self.context = context
        _name = State(initialValue: bank.name)
        _providerType = State(initialValue: bank.providerType.rawValue)
    }

    var body: some View {
        FDSSheet(
            title: "Edit Bank",
            subtitle: bank.name,
            onDismiss: { dismiss() }
        ) {
            VStack(alignment: .leading, spacing: 20) {
                FDSCard(cornerRadius: 12, padded: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("BANK INFORMATION")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.2)
                            .foregroundColor(DesignTokens.Text.secondary)

                        fieldInput("Bank Name", text: $name)
                        Divider().opacity(DesignTokens.Opacity.low)
                        fieldInput("Provider Type", text: $providerType)
                    }
                    .padding(12)
                }

                FDSCard(cornerRadius: 12, padded: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: { showDeleteConfirm = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Delete Bank")
                                    .font(.system(size: 13, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(Color(red: 1.0, green: 0.27, blue: 0.23))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .alert("Delete Bank?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await context.deleteBank(id: bank.id)
                    if context.error == nil { dismiss() }
                }
            }
        } message: {
            Text("This will permanently delete this bank and all associated accounts/cards/transactions.")
        }
    }

    private func fieldInput(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.2)
                .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
            FDSTextInput("", text: text, style: .labelSmall)
                .foregroundColor(DesignTokens.Text.primary)
                .padding(8)
                .background(DesignTokens.Background.inputWell)
                .cornerRadius(6)
        }
    }
}
