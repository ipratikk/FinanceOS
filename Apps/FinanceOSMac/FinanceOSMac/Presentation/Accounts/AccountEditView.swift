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
            onDismiss: { dismiss() },
            content: {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    FDSCard(cornerRadius: 12, padded: false) {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            FDSLabel("ACCOUNT INFORMATION")
                                .font(AppTypography.captionSmSemibold)
                                .tracking(0.2)
                                .foregroundColor(DesignTokens.Text.secondary)

                            fieldInput("Account Name", text: $displayName)
                            Divider().opacity(DesignTokens.Opacity.low)
                            fieldInput("Owner Name", text: $ownerName)
                            Divider().opacity(DesignTokens.Opacity.low)
                            fieldInput("Last 4 Digits", text: $last4)
                            Divider().opacity(DesignTokens.Opacity.low)
                            fieldInput("Nickname", text: $nickname)
                        }
                        .padding(AppSpacing.xs)
                    }

                    FDSCard(cornerRadius: 12, padded: false) {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            FDSLabel("BANK")
                                .font(AppTypography.captionSmSemibold)
                                .tracking(0.2)
                                .foregroundColor(DesignTokens.Text.secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                FDSLabel("Select Bank")
                                    .font(AppTypography.captionSmMedium)
                                    .foregroundColor(DesignTokens.Text.primary)
                                Picker("Bank", selection: $bankId) {
                                    ForEach(context.banks) { bank in
                                        FDSLabel(bank.name).tag(bank.id)
                                    }
                                }
                                .foregroundColor(DesignTokens.Text.primary)
                            }
                            .padding(AppSpacing.xs)
                        }

                        FDSCard(cornerRadius: 12, padded: false) {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                FDSLiquidButton("Delete Account", symbol: "trash.fill", variant: .danger) {
                                    showDeleteConfirm = true
                                }
                                .padding(AppSpacing.xs)
                            }
                        }
                    }
                }
            }
        )
        .alert("Delete Account?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await context.deleteAccount(id: account.id)
                    if context.deleteError == nil { dismiss() }
                }
            }
        } message: {
            FDSLabel("This will permanently delete this account and all associated transactions.")
        }
        .alert("Error", isPresented: Binding(
            get: { context.deleteError != nil },
            set: { if !$0 { context.clearError() } }
        )) {
            Button("OK") { context.clearError() }
        } message: {
            if let error = context.deleteError {
                FDSLabel(error)
            }
        }
    }

    private func fieldInput(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            FDSLabel(label.uppercased())
                .font(AppTypography.captionSmSemibold)
                .tracking(0.2)
                .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
            FDSTextInput("", text: text, style: .labelSmall)
                .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                .padding(8)
                .background(DesignTokens.Background.inputWell)
                .cornerRadius(6)
        }
    }
}
