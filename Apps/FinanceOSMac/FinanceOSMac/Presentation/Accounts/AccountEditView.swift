import FinanceCore
import FinanceUI
import SwiftUI

struct AccountEditView: View {
    let account: Ledger
    let context: AccountEditContext
    @State private var displayName: String
    @State private var last4: String
    @State private var ownerName: String
    @State private var accountType: String
    @State private var nickname: String
    @State private var bankId: UUID
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirm = false

    init(account: Ledger, context: AccountEditContext) {
        self.account = account
        self.context = context
        _displayName = State(initialValue: account.displayName)
        _last4 = State(initialValue: account.last4)
        _ownerName = State(initialValue: account.ownerName)
        _accountType = State(initialValue: account.accountType ?? "savings")
        _nickname = State(initialValue: account.nickname)
        _bankId = State(initialValue: account.bankId)
    }

    var body: some View {
        FDSSheet(
            title: "Edit Account",
            subtitle: account.displayName,
            onDismiss: { dismiss() }
        ) {
            VStack(alignment: .leading, spacing: 20) {
                FDSCard(cornerRadius: 12, padded: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ACCOUNT INFORMATION")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.2)
                            .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))

                        fieldInput("Account Name", text: $displayName)
                        Divider().opacity(0.2)
                        fieldInput("Owner Name", text: $ownerName)
                        Divider().opacity(0.2)
                        fieldInput("Last 4 Digits", text: $last4)
                        Divider().opacity(0.2)
                        fieldInput("Nickname", text: $nickname)
                    }
                    .padding(12)
                }

                FDSCard(cornerRadius: 12, padded: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("BANK")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.2)
                            .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Select Bank")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                            Picker("Bank", selection: $bankId) {
                                ForEach(context.banks) { bank in
                                    Text(bank.name).tag(bank.id)
                                }
                            }
                            .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                        }
                        .padding(8)
                    }
                    .padding(12)
                }

                FDSCard(cornerRadius: 12, padded: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: { showDeleteConfirm = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Delete Account")
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
        .alert("Delete Account?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await context.deleteAccount(id: account.id)
                    if context.deleteError == nil { dismiss() }
                }
            }
        } message: {
            Text("This will permanently delete this account and all associated transactions.")
        }
        .alert("Error", isPresented: Binding(
            get: { context.deleteError != nil },
            set: { if !$0 { context.clearError() } }
        )) {
            Button("OK") { context.clearError() }
        } message: {
            if let error = context.deleteError {
                Text(error)
            }
        }
    }

    private func fieldInput(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.2)
                .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
            TextField("", text: text)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                .padding(8)
                .background(Color.black.opacity(0.25))
                .cornerRadius(6)
        }
    }
}
