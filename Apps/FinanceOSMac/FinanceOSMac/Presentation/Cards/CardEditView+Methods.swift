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
        FDSInputField(label, text: text, placeholder: placeholder)
    }

    func catalogCardWidget(_ card: CardMetadata) -> some View {
        CardCatalogWidget(card: card)
    }

    var cardTypeOptions: [FDSPickerOption] {
        CardNetwork.allCases.map { network in
            FDSPickerOption(
                id: network.rawValue,
                value: network,
                title: network.displayName,
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
                    get: { viewModel.form.accountType },
                    set: { if let value = $0 { viewModel.form.accountType = value } }
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
            selection: Binding(
                get: { viewModel.form.selectedBank },
                set: { viewModel.form.selectedBank = $0 }
            ),
            options: bankOptions,
            variant: .symbolText,
            placeholder: "Select bank"
        )
    }
}
