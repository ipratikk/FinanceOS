import FinanceCore
import FinanceUI
import SwiftUI

struct CreateNewTargetSheet: View {
    @Binding var state: TargetCreationState
    let banks: [Bank]
    let detectedBank: String
    let onCancel: () -> Void
    let onCreate: () -> Void

    @State private var showCardSelection = false

    var selectedBank: Bank? {
        guard let id = state.selectedBankID else { return nil }
        return banks.first { $0.id == id }
    }

    var isCard: Bool {
        state.isCard
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                FDSLabel(isCard ? "Create New Card" : "Create New Account", style: .headingMedium)
                Spacer()
                Button(action: { onCancel() }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .headingSmall()
                        .foregroundStyle(AppColors.textSecondary)
                })
            }
            .padding(AppSpacing.md)
            .background(AppColors.base)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    FDSGlassSurface(cornerRadius: AppRadius.lg) {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            FDSLabel("BASIC INFORMATION", style: .subheading)

                            VStack(spacing: AppSpacing.sm) {
                                inputField("Name (Optional)", text: $state.customName)

                                if !isCard {
                                    inputField("Owner Name", text: $state.ownerName)
                                }

                                if isCard {
                                    inputField("Nickname", text: $state.nickname)
                                }

                                inputField("Last 4 Digits", text: $state.last4)
                                    .onChange(of: state.last4) { _, newValue in
                                        if newValue.count > 4 {
                                            state.last4 = String(newValue.prefix(4))
                                        }
                                    }

                                if isCard {
                                    cardTypeField()
                                }

                                if !isCard {
                                    accountTypeField()
                                }
                            }
                        }
                    }

                    FDSGlassSurface(cornerRadius: AppRadius.lg) {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            FDSLabel("BANK & ACCOUNT", style: .subheading)

                            bankField()
                        }
                    }
                }
                .padding(AppSpacing.md)
            }

            Divider().opacity(0.3)

            HStack(spacing: AppSpacing.compact) {
                FDSLiquidButton("Cancel", variant: .subtle) { onCancel() }
                Spacer()
                FDSLiquidButton("Create", variant: .primary) { onCreate() }
                    .disabled(state.last4.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(AppSpacing.md)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.base)
        .sheet(isPresented: $showCardSelection) {
            CardSelectionView(
                onSelect: { card in
                    state.cardType = card.cardType
                    state.cardProduct = card.id
                    print("[CreateNewTargetSheet] Selected card: '\(card.name)' (id=\(card.id))")
                    showCardSelection = false
                },
                onDismiss: { showCardSelection = false }
            )
            .frame(minWidth: 520, minHeight: 600)
        }
    }

    private func inputField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            FDSLabel(label, style: .hint)
            FDSTextInput("", text: text, style: .bodyMedium)
                .padding(AppSpacing.xs)
                .background(AppColors.surface2)
                .cornerRadius(AppRadius.sm)
        }
    }

    private func autoDetectCardType() {
        let cardNumberToUse = !state.maskedCardNumber.isEmpty ? state.maskedCardNumber : state.last4
        let detectedType = BINParser.detectCardType(from: cardNumberToUse)
        state.cardType = detectedType
    }

    private func cardTypeField() -> some View {
        let cardTypeOptions = [
            FDSPickerOption(value: "visa", title: "Visa", symbol: "creditcard.fill"),
            FDSPickerOption(value: "mastercard", title: "Mastercard", symbol: "creditcard.fill"),
            FDSPickerOption(value: "amex", title: "American Express", symbol: "creditcard.fill"),
            FDSPickerOption(value: "discover", title: "Discover", symbol: "creditcard.fill"),
            FDSPickerOption(value: "diners", title: "Diners Club", symbol: "creditcard.fill"),
            FDSPickerOption(value: "other", title: "Other", symbol: "creditcard.fill")
        ]

        return VStack(alignment: .leading, spacing: AppSpacing.tight) {
            HStack {
                FDSLabel("Card Network", style: .hint)
                Spacer()
                Button(action: { autoDetectCardType() }) {
                    FDSLabel("Auto-detect", style: .caption, color: .secondary)
                }
                .disabled(state.last4.trimmingCharacters(in: .whitespaces).count < 4)
            }

            FDSPicker(
                selection: $state.cardType,
                options: cardTypeOptions,
                variant: .symbolOnly,
                placeholder: "Select network"
            )

            Button(action: { showCardSelection = true }) {
                HStack(spacing: AppSpacing.compact) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 11, weight: .semibold))
                    FDSLabel("Browse Card Database", style: .bodyMedium)
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

    private func accountTypeField() -> some View {
        let accountTypeOptions = [
            FDSPickerOption(value: "savings", title: "Savings"),
            FDSPickerOption(value: "checking", title: "Checking"),
            FDSPickerOption(value: "money_market", title: "Money Market"),
            FDSPickerOption(value: "other", title: "Other")
        ]

        return VStack(alignment: .leading, spacing: AppSpacing.tight) {
            FDSLabel("Account Type", style: .hint)

            FDSPicker(
                selection: $state.accountType,
                options: accountTypeOptions,
                variant: .textOnly,
                placeholder: "Select type"
            )
        }
    }

    private func bankField() -> some View {
        let bankOptions = banks.map { bank in
            FDSPickerOption(
                value: bank.id,
                title: bank.name,
                symbol: "building.columns.fill"
            )
        }

        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.tight) {
                FDSLabel("Current Bank", style: .hint)

                HStack {
                    if let bank = selectedBank {
                        FDSLabel(bank.name, style: .caption)
                    } else {
                        FDSLabel(detectedBank, style: .caption)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.xs)
                .background(AppColors.surface2)
                .cornerRadius(AppRadius.sm)
            }

            if !banks.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.tight) {
                    FDSLabel(
                        selectedBank == nil ? "Select Bank" : "Change Bank",
                        style: .hint
                    )

                    FDSPicker(
                        selection: $state.selectedBankID,
                        options: bankOptions,
                        variant: .textOnly,
                        placeholder: "Select bank"
                    )
                }
            }
        }
    }
}
