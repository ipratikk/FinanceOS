import FinanceCore
import FinanceUI
import SwiftUI

extension CardEditView {
    func inputField(
        _ label: String,
        placeholder: String = "",
        text: Binding<String>,
        style: FDSTextInputStyle = .bodyLarge
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.compact) {
            FDSLabel(label)
                .font(AppTypography.captionSm)
                .tracking(1.0)
                .foregroundStyle(AppColors.Text.secondary)
            FDSTextInput(placeholder, text: text, style: style)
                .cornerRadius(AppRadius.sm)
        }
    }

    func catalogCardWidget(_ card: CardMetadata) -> some View {
        CardCatalogWidget(card: card)
    }

    var cardTypeOptions: [FDSPickerOption] {
        CardNetwork.allCases.map { network in
            let displayName: String = switch network {
            case .visa: "Visa"
            case .mastercard: "Mastercard"
            case .amex: "American Express"
            case .discover: "Discover"
            case .diners: "Diners Club"
            case .rupay: "RuPay"
            case .other: "Other"
            }
            return FDSPickerOption(
                id: network.rawValue,
                value: network,
                title: displayName,
                symbol: network.symbolAssetName == nil ? "creditcard.fill" : nil,
                imageName: network.symbolAssetName
            )
        }
    }

    func accountTypeField() -> some View {
        let options = [
            FDSPickerOption(id: "savings", value: "savings", title: "Savings", symbol: "building.columns.fill"),
            FDSPickerOption(id: "checking", value: "checking", title: "Checking", symbol: "checkmark.rectangle.fill"),
            FDSPickerOption(
                id: "money_market", value: "money_market", title: "Money Market", symbol: "chart.line.uptrend.xyaxis"
            ),
            FDSPickerOption(id: "other", value: "other", title: "Other", symbol: "banknote.fill")
        ]
        return VStack(alignment: .leading, spacing: AppSpacing.tight) {
            FDSLabel("ACCOUNT TYPE")
                .font(AppTypography.captionSm)
                .tracking(1.0)
                .foregroundStyle(AppColors.Text.secondary)
            FDSPicker(
                selection: Binding(
                    get: { form.accountType },
                    set: { if let value = $0 { form.accountType = value } }
                ),
                options: options,
                variant: .symbolText,
                placeholder: "Select type"
            )
        }
    }

    func bankField() -> some View {
        let bankOptions = Banks.allCases.map {
            FDSPickerOption(id: $0.rawValue, value: $0, title: $0.displayName, imageName: $0.symbolAssetName)
        }
        return FDSPicker(
            selection: Binding(get: { form.selectedBank }, set: { form.selectedBank = $0 }),
            options: bankOptions,
            variant: .symbolText,
            placeholder: "Select bank"
        )
    }

    // MARK: - Business Logic

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
