import FinanceCore
import FinanceUI
import SwiftUI

struct CardEditView: View {
    let card: Ledger
    let context: CardEditContext
    @State private var displayName: String
    @State private var last4: String
    @State private var cardType: String
    @State private var nickname: String
    @State private var bankId: UUID
    @State private var linkedLedgerId: UUID?
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirm = false
    @State private var showCardSelection = false

    init(card: Ledger, context: CardEditContext) {
        self.card = card
        self.context = context
        _displayName = State(initialValue: card.displayName)
        _last4 = State(initialValue: card.last4)
        _cardType = State(initialValue: card.cardType ?? "other")
        _nickname = State(initialValue: card.nickname)
        _bankId = State(initialValue: card.bankId)
        _linkedLedgerId = State(initialValue: card.linkedLedgerId)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.3)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    cardSection
                    bankSection
                    deleteSection
                }
                .padding(AppSpacing.xl)
            }

            Divider().opacity(0.3)
            footer
        }
        .frame(width: 540, height: 720)
        .background(AppColors.base)
        .alert("Delete Card?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await context.deleteCard(id: card.id)
                    if context.deleteError == nil { dismiss() }
                }
            }
        } message: {
            Text("This will permanently delete this card and all associated transactions.")
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
        .sheet(isPresented: $showCardSelection) {
            CardSelectionView(
                onSelect: { selected in
                    cardType = selected.cardType
                    showCardSelection = false
                },
                onDismiss: { showCardSelection = false }
            )
            .frame(minWidth: 520, minHeight: 600)
        }
    }

    private var header: some View {
        HStack(spacing: AppSpacing.compact) {
            FDSMerchantAvatar(name: card.displayName, symbol: "creditcard.fill", size: 32)
            VStack(alignment: .leading, spacing: 0) {
                Text("Edit Card")
                    .bodyMedium()
                Text(card.displayName)
                    .font(.system(size: 11))
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
        }
        .padding(AppSpacing.md)
    }

    private var cardSection: some View {
        FDSGlassSurface(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("CARD INFORMATION")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)

                field("Card Name") { FDSTextInput("Name", text: $displayName) }
                field("Last 4 Digits") {
                    FDSTextInput("Last 4", text: $last4)
                        .onChange(of: last4) { _, value in
                            if value.count > 4 { last4 = String(value.prefix(4)) }
                        }
                }
                fieldWithAction(
                    "Card Network",
                    actionLabel: "Auto-detect",
                    actionDisabled: last4.trimmingCharacters(in: .whitespaces).count < 4,
                    action: autoDetectCardType
                ) {
                    let cardTypeOptions = [
                        FDSPickerOption(id: "visa", value: "visa", title: "Visa", imageName: "visa"),
                        FDSPickerOption(
                            id: "mastercard",
                            value: "mastercard",
                            title: "Mastercard",
                            imageName: "mastercard"
                        ),
                        FDSPickerOption(id: "amex", value: "amex", title: "American Express", imageName: "amex-symbol"),
                        FDSPickerOption(
                            id: "discover",
                            value: "discover",
                            title: "Discover",
                            symbol: "creditcard.fill"
                        ),
                        FDSPickerOption(id: "diners", value: "diners", title: "Diners Club", imageName: "diners"),
                        FDSPickerOption(id: "other", value: "other", title: "Other", symbol: "creditcard.fill")
                    ]
                    FDSPicker(
                        selection: Binding(
                            get: { cardType },
                            set: { if let value = $0 { cardType = value } }
                        ),
                        options: cardTypeOptions,
                        variant: .symbolOnly,
                        placeholder: "Select network"
                    )
                }

                Button(action: { showCardSelection = true }) {
                    HStack(spacing: AppSpacing.compact) {
                        Image(systemName: "creditcard.fill")
                            .labelSmall()
                        Text("Browse Card Database")
                            .labelSmall()
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(AppColors.accent)
                    .padding(.horizontal, AppSpacing.compact)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var bankSection: some View {
        FDSGlassSurface(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("BANK & ACCOUNT")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)

                field("Bank") {
                    let bankOptions = context.banks.map { bank in
                        FDSPickerOption(
                            id: bank.id,
                            value: bank.id,
                            title: bank.name,
                            symbol: "building.columns.fill",
                            imageName: bank.symbolAssetName
                        )
                    }
                    FDSPicker(
                        selection: Binding(
                            get: { bankId },
                            set: { if let value = $0 { bankId = value } }
                        ),
                        options: bankOptions,
                        variant: .textOnly,
                        placeholder: "Select bank"
                    )
                }
                field("Linked Account") {
                    let filtered = context.accounts.filter { $0.bankId == bankId }
                    let allOptions: [FDSPickerOption] = {
                        var options = [FDSPickerOption(id: "none", value: nil as UUID?, title: "None")]
                        options += filtered.map { account in
                            FDSPickerOption(id: account.id, value: account.id, title: account.displayName)
                        }
                        return options
                    }()
                    return FDSPicker(
                        selection: $linkedLedgerId,
                        options: allOptions,
                        variant: .textOnly,
                        placeholder: "Select account"
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
                    .font(.system(size: 12, weight: .semibold))
                Text("Delete Card")
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
                        id: card.id,
                        bankId: bankId,
                        kind: card.kind,
                        displayName: displayName,
                        last4: last4,
                        nickname: nickname,
                        ownerName: card.ownerName,
                        createdAt: card.createdAt,
                        accountType: card.accountType,
                        cardType: cardType,
                        cardProduct: card.cardProduct,
                        linkedLedgerId: linkedLedgerId,
                        isArchived: card.isArchived
                    )
                    await context.updateCard(updated)
                    if context.deleteError == nil { dismiss() }
                }
            }
        }
        .padding(AppSpacing.md)
    }

    private func autoDetectCardType() {
        cardType = BINParser.detectCardType(from: last4)
    }

    private func field(
        _ label: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.tight) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.tertiary)
            content()
        }
    }

    private func fieldWithAction(
        _ label: String,
        actionLabel: String,
        actionDisabled: Bool,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.tight) {
            HStack {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button(actionLabel, action: action)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(actionDisabled ? AnyShapeStyle(.tertiary) : AnyShapeStyle(AppColors.accent))
                    .disabled(actionDisabled)
                    .buttonStyle(.plain)
            }
            content()
        }
    }
}
