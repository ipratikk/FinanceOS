import FinanceCore
import FinanceUI
import SwiftUI

extension CardEditView {
    var headerBar: some View {
        HStack {
            FDSLabel(titleText, style: .headingMedium)
            Spacer()
            Button(action: { dismiss() }, label: {
                Image(systemName: "xmark.circle.fill")
                    .headingSmall()
                    .foregroundStyle(AppColors.textSecondary)
            })
        }
        .padding(AppSpacing.md)
        .background(AppColors.base)
    }

    var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                basicInfoSurface
                bankSurface
                if isEdit { dangerZoneSurface }
            }
            .padding(AppSpacing.md)
        }
    }

    var basicInfoSurface: some View {
        FDSGlassSurface(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                FDSLabel("BASIC INFORMATION", style: .subheading)
                VStack(spacing: AppSpacing.md) {
                    if isCard { cardBasicFields } else { accountBasicFields }
                }
            }
        }
    }

    @ViewBuilder var cardBasicFields: some View {
        inputField("Nickname", text: $form.nickname)
        if !form.cardProductId.isEmpty, let catalogCard = selectedCatalogCard {
            catalogCardWidget(catalogCard)
        } else {
            cardBrowseButton
        }
        CardDisplayPreview(
            cardName: selectedCatalogCard?.name,
            bankName: form.selectedBank?.displayName,
            cardholderName: form.cardholderName,
            cardNetwork: form.cardType,
            first4: form.first4,
            last4: form.last4,
            bankLogo: form.selectedBank?.logoAssetName
        )
        cardNumberRow
        inputField("Cardholder Name", text: $form.cardholderName)
    }

    @ViewBuilder var accountBasicFields: some View {
        inputField("Account Name (Optional)", text: $form.customName)
        inputField("Account Holder", text: $form.cardholderName)
        inputField("Last 4 Digits", text: $form.last4)
            .onChange(of: form.last4) { _, newValue in
                if newValue.count > 4 { form.last4 = String(newValue.prefix(4)) }
            }
        accountTypeField()
    }

    var cardBrowseButton: some View {
        Button(action: { showCardSelection = true }, label: {
            HStack(spacing: AppSpacing.compact) {
                Image(systemName: "creditcard.fill")
                Text("Browse Card Database")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(AppColors.accent)
            .padding(.horizontal, AppSpacing.compact)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
    }

    var cardNumberRow: some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.tight) {
                FDSLabel("First 4 (Optional)", style: .hint)
                FDSTextInput("", text: $form.first4, style: .bodyMedium)
                    .padding(AppSpacing.xs)
                    .cornerRadius(AppRadius.sm)
            }
            VStack(alignment: .leading, spacing: AppSpacing.tight) {
                FDSLabel("Last 4", style: .hint)
                FDSTextInput("", text: $form.last4, style: .bodyMedium)
                    .padding(AppSpacing.xs)
                    .cornerRadius(AppRadius.sm)
                    .onChange(of: form.last4) { _, newValue in
                        if newValue.count > 4 { form.last4 = String(newValue.prefix(4)) }
                    }
            }
            VStack(alignment: .leading, spacing: AppSpacing.tight) {
                FDSLabel("Card Network", style: .hint)
                FDSPicker(
                    selection: Binding<CardNetwork?>(
                        get: { form.cardType },
                        set: { if let value = $0 { form.cardType = value } }
                    ),
                    options: cardTypeOptions,
                    variant: .logoOnly,
                    placeholder: "Select"
                )
            }
        }
    }

    var bankSurface: some View {
        FDSGlassSurface(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                FDSLabel("BANK & ACCOUNT", style: .subheading)
                bankField()
            }
        }
    }

    var dangerZoneSurface: some View {
        FDSGlassSurface(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                FDSLabel("DANGER ZONE", style: .subheading)
                FDSLiquidButton(
                    "Delete \(isCard ? "Card" : "Account")",
                    symbol: "trash.fill",
                    variant: .danger
                ) {
                    showDeleteConfirm = true
                }
            }
        }
    }

    var footerBar: some View {
        HStack(spacing: AppSpacing.compact) {
            FDSLiquidButton("Cancel", variant: .ghost) { dismiss() }
            Spacer()
            primaryActionButton
        }
        .padding(AppSpacing.md)
    }

    @ViewBuilder var primaryActionButton: some View {
        switch mode {
        case let .edit(card, context):
            FDSLiquidButton("Save", variant: .primary) {
                Task {
                    await commitEdit(card: card, context: context)
                    dismiss()
                }
            }
            .disabled(form.last4.trimmingCharacters(in: .whitespaces).isEmpty)
        case let .createCard(_, onCommit), let .createAccount(_, onCommit):
            FDSLiquidButton("Create", variant: .primary) {
                onCommit(buildCreationState())
                dismiss()
            }
            .disabled(form.last4.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    @ViewBuilder var deleteSheet: some View {
        if case let .edit(card, context) = mode {
            CardDeleteConfirmationAlert(
                isCard: isCard,
                card: card,
                context: context,
                isPresented: $showDeleteConfirm
            )
        }
    }

    var cardSelectionSheet: some View {
        CardSelectionView(
            onSelect: { card in
                if form.customName.trimmingCharacters(in: .whitespaces).isEmpty {
                    form.customName = card.name
                }
                form.cardType = card.cardType
                form.cardProductId = card.id
                showCardSelection = false
            },
            onDismiss: { showCardSelection = false }
        )
        .frame(minWidth: 700, maxHeight: 500)
    }

    func buildCreationState() -> TargetCreationState {
        var state = TargetCreationState()
        state.customName = form.customName
        state.nickname = form.nickname
        state.first4 = form.first4
        state.last4 = form.last4
        state.cardholderName = form.cardholderName
        state.selectedBank = form.selectedBank
        state.isCard = isCard
        state.accountType = form.accountType
        state.cardType = form.cardType
        state.cardProductId = form.cardProductId
        state.linkedLedgerId = form.linkedLedgerId
        return state
    }

    func commitEdit(card: Ledger, context: CardEditContext) async {
        let newBankId = context.banks.first { $0.bank == form.selectedBank }?.id ?? card.bankId
        let updated = Ledger(
            id: card.id,
            bankId: newBankId,
            kind: card.kind,
            displayName: form.customName.isEmpty ? card.displayName : form.customName,
            last4: form.last4,
            nickname: form.nickname,
            ownerName: form.cardholderName,
            createdAt: card.createdAt,
            accountType: !isCard ? form.accountType : nil,
            cardType: isCard ? form.cardType : nil,
            cardProductId: form.cardProductId.isEmpty ? nil : form.cardProductId,
            bin: card.bin,
            linkedLedgerId: form.linkedLedgerId,
            isArchived: card.isArchived,
            closingBalance: card.closingBalance,
            closingBalanceAsOf: card.closingBalanceAsOf
        )
        await context.updateCard(updated)
    }
}
