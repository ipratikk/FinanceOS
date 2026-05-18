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
        VStack(spacing: 0) {
            header
            Divider().opacity(0.3)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    accountSection
                    bankSection
                    deleteSection
                }
                .padding(AppSpacing.xl)
            }

            Divider().opacity(0.3)
            footer
        }
        .frame(width: 520, height: 680)
        .background(AppColors.base)
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
        .alert("Delete Failed", isPresented: Binding(
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

    private var header: some View {
        HStack(spacing: AppSpacing.compact) {
            FDSMerchantAvatar(name: account.displayName, symbol: "building.columns.fill", size: 32)
            VStack(alignment: .leading, spacing: 0) {
                Text("Edit Account")
                    .bodyMedium()
                Text(account.displayName)
                    .font(AppTypography.captionSm)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .labelSmall()
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .padding(AppSpacing.md)
    }

    private var accountSection: some View {
        FDSGlassSurface(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("ACCOUNT INFORMATION")
                    .font(AppTypography.labelSemibold)
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)

                field("Account Name") { FDSTextInput("Name", text: $displayName) }
                field("Owner Name") { FDSTextInput("Owner", text: $ownerName) }
                field("Last 4 Digits") { FDSTextInput("Last 4", text: $last4) }
                field("Account Type") {
                    let accountTypeOptions = [
                        FDSPickerOption(
                            id: "savings",
                            value: "savings",
                            title: "Savings",
                            symbol: "building.columns.fill"
                        ),
                        FDSPickerOption(
                            id: "checking",
                            value: "checking",
                            title: "Checking",
                            symbol: "checkmark.rectangle.fill"
                        ),
                        FDSPickerOption(
                            id: "credit",
                            value: "credit",
                            title: "Credit",
                            symbol: "creditcard.fill"
                        )
                    ]
                    FDSPicker(
                        selection: Binding(
                            get: { accountType },
                            set: { if let value = $0 { accountType = value } }
                        ),
                        options: accountTypeOptions,
                        variant: .symbolText,
                        placeholder: "Select type"
                    )
                }
            }
        }
    }

    private var bankSection: some View {
        FDSGlassSurface(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("BANK & NICKNAME")
                    .font(AppTypography.labelSemibold)
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)

                field("Bank") {
                    let bankOptions = context.banks.map { bank in
                        FDSPickerOption(
                            id: bank.id,
                            value: bank.id,
                            title: bank.name,
                            imageName: bank.symbolAssetName
                        )
                    }
                    FDSPicker(
                        selection: Binding(
                            get: { bankId },
                            set: { if let value = $0 { bankId = value } }
                        ),
                        options: bankOptions,
                        variant: .symbolText,
                        placeholder: "Select bank"
                    )
                }
                field("Nickname (Optional)") { FDSTextInput("Nickname", text: $nickname) }
            }
        }
    }

    private var deleteSection: some View {
        Button(action: { showDeleteConfirm = true }) {
            HStack(spacing: AppSpacing.compact) {
                Image(systemName: "trash.fill")
                    .font(AppTypography.captionLgSemibold)
                Text("Delete Account")
                    .caption()
                Spacer()
            }
            .foregroundStyle(AppColors.debit)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.compact)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .fill(AppColors.debit.opacity(0.12))
            }
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack(spacing: AppSpacing.compact) {
            FDSLiquidButton("Cancel", variant: .subtle) { dismiss() }
            Spacer()
            FDSLiquidButton("Save", variant: .primary) {
                Task {
                    let updated = Ledger(
                        id: account.id,
                        bankId: bankId,
                        kind: account.kind,
                        displayName: displayName,
                        last4: last4,
                        nickname: nickname,
                        ownerName: ownerName,
                        createdAt: account.createdAt,
                        accountType: accountType,
                        cardType: account.cardType,
                        cardProduct: account.cardProduct,
                        linkedLedgerId: account.linkedLedgerId,
                        isArchived: account.isArchived,
                        closingBalance: account.closingBalance,
                        closingBalanceAsOf: account.closingBalanceAsOf
                    )
                    await context.updateAccount(updated)
                    if context.deleteError == nil { dismiss() }
                }
            }
        }
        .padding(AppSpacing.md)
    }

    private func field(
        _ label: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.tight) {
            Text(label.uppercased())
                .font(AppTypography.labelSemibold)
                .tracking(0.6)
                .foregroundStyle(.tertiary)
            content()
        }
    }
}
