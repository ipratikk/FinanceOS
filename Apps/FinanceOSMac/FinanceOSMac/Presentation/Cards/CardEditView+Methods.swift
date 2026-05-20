import FinanceCore
import FinanceUI
import SwiftUI

extension CardEditView {
    func inputField(_ label: String, text: Binding<String>, style: FDSTextInputStyle = .bodyMedium) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            FDSLabel(label, style: .hint)
            FDSTextInput("", text: text, style: style)
                .padding(AppSpacing.xs)
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
                id: "money_market",
                value: "money_market",
                title: "Money Market",
                symbol: "chart.line.uptrend.xyaxis"
            ),
            FDSPickerOption(
                id: "other",
                value: "other",
                title: "Other",
                symbol: "banknote.fill"
            )
        ]

        return VStack(alignment: .leading, spacing: AppSpacing.tight) {
            FDSLabel("Account Type", style: .hint)
            FDSPicker(
                selection: Binding(
                    get: { form.accountType },
                    set: { if let value = $0 { form.accountType = value } }
                ),
                options: accountTypeOptions,
                variant: .symbolText,
                placeholder: "Select type"
            )
        }
    }

    func bankField() -> some View {
        let bankOptions = Banks.allCases.map {
            FDSPickerOption(id: $0.rawValue, value: $0, title: $0.displayName, imageName: $0.symbolAssetName)
        }
        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.tight) {
                FDSLabel("Bank", style: .hint)
                FDSPicker(
                    selection: Binding(get: { form.selectedBank }, set: { form.selectedBank = $0 }),
                    options: bankOptions,
                    variant: .symbolText,
                    placeholder: "Select bank"
                )
            }
        }
    }
}
