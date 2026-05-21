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
    @State private var isSaving = false
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

    private var hasChanges: Bool {
        displayName != account.displayName ||
            last4 != account.last4 ||
            ownerName != account.ownerName ||
            accountType != (account.accountType ?? "savings") ||
            nickname != account.nickname ||
            bankId != account.bankId
    }

    var body: some View {
        FDSSheet(
            title: "Edit Account",
            subtitle: account.displayName,
            onDismiss: { dismiss() },
            content: {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    FDSCard(padded: false) {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            FDSLabel("ACCOUNT INFORMATION")
                                .font(AppTypography.captionSmSemibold)
                                .tracking(0.2)
                                .foregroundColor(AppColors.Text.secondary)

                            fieldInput("Account Name", text: $displayName)
                            Divider().opacity(AppColors.Opacity.low)
                            fieldInput("Owner Name", text: $ownerName)
                            Divider().opacity(AppColors.Opacity.low)
                            fieldInput("Last 4 Digits", text: $last4)
                            Divider().opacity(AppColors.Opacity.low)
                            fieldInput("Nickname", text: $nickname)
                        }
                        .padding(AppSpacing.xs)
                    }

                    FDSCard(padded: false) {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            FDSLabel("BANK")
                                .font(AppTypography.captionSmSemibold)
                                .tracking(0.2)
                                .foregroundColor(AppColors.Text.secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                FDSLabel("Select Bank")
                                    .font(AppTypography.captionSmMedium)
                                    .foregroundColor(AppColors.Text.primary)
                                Picker("Bank", selection: $bankId) {
                                    ForEach(context.banks) { bank in
                                        FDSLabel(bank.name).tag(bank.id)
                                    }
                                }
                                .foregroundColor(AppColors.Text.primary)
                            }
                            .padding(AppSpacing.xs)
                        }
                    }

                    FDSCard(padded: false) {
                        FDSLiquidButton("Delete Account", symbol: "trash.fill", variant: .danger) {
                            showDeleteConfirm = true
                        }
                        .padding(AppSpacing.xs)
                    }

                    // Save
                    FDSLiquidButton(
                        "Save Changes",
                        symbol: "checkmark",
                        variant: .primary,
                        isEnabled: hasChanges && !isSaving,
                        isLoading: isSaving
                    ) {
                        Task { await saveChanges() }
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

    private func saveChanges() async {
        isSaving = true
        defer { isSaving = false }
        let updated = Ledger(
            id: account.id,
            bankId: bankId,
            kind: account.kind,
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            last4: last4.trimmingCharacters(in: .whitespaces),
            nickname: nickname.trimmingCharacters(in: .whitespaces),
            ownerName: ownerName.trimmingCharacters(in: .whitespaces),
            createdAt: account.createdAt,
            accountType: accountType,
            cardType: account.cardType,
            cardProductId: account.cardProductId,
            bin: account.bin,
            linkedLedgerId: account.linkedLedgerId,
            isArchived: account.isArchived,
            closingBalance: account.closingBalance,
            closingBalanceAsOf: account.closingBalanceAsOf
        )
        await context.updateAccount(updated)
        if context.deleteError == nil { dismiss() }
    }

    private func fieldInput(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            FDSLabel(label.uppercased())
                .font(AppTypography.captionSmSemibold)
                .tracking(0.2)
                .foregroundColor(AppColors.Text.secondary)
            FDSTextInput("", text: text, style: .labelSmall)
                .foregroundColor(AppColors.Text.primary)
                .padding(8)
                .background(AppColors.Glass.inputWell)
                .cornerRadius(AppRadius.sm)
        }
    }
}
