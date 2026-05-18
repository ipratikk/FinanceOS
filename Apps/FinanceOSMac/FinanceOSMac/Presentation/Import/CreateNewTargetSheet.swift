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
                            Text("BASIC INFORMATION")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(0.6)
                                .foregroundStyle(.tertiary)

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
                            Text("BANK & ACCOUNT")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(0.6)
                                .foregroundStyle(.tertiary)

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
        VStack(alignment: .leading, spacing: AppSpacing.tight) {
            HStack {
                Text("CARD NETWORK")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button(action: { autoDetectCardType() }) {
                    Text("Auto-detect")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(
                            state.last4.trimmingCharacters(in: .whitespaces).count < 4
                                ? AnyShapeStyle(.tertiary)
                                : AnyShapeStyle(AppColors.accent)
                        )
                        .disabled(state.last4.trimmingCharacters(in: .whitespaces).count < 4)
                }
                .buttonStyle(.plain)
            }

            Picker("", selection: $state.cardType) {
                Text("Visa").tag("visa")
                Text("Mastercard").tag("mastercard")
                Text("American Express").tag("amex")
                Text("Discover").tag("discover")
                Text("Diners Club").tag("diners")
                Text("Other").tag("other")
            }
            .pickerStyle(.menu)
            .labelsHidden()

            Button(action: { showCardSelection = true }) {
                HStack(spacing: AppSpacing.compact) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Browse Card Database")
                        .font(.system(size: 12, weight: .medium))
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
        VStack(alignment: .leading, spacing: AppSpacing.tight) {
            Text("ACCOUNT TYPE")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.tertiary)

            Picker("", selection: $state.accountType) {
                Text("Savings").tag("savings")
                Text("Checking").tag("checking")
                Text("Money Market").tag("money_market")
                Text("Other").tag("other")
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
    }

    private func bankField() -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.tight) {
                Text("CURRENT BANK")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.tertiary)

                HStack {
                    if let bank = selectedBank {
                        Text(bank.name)
                            .font(.system(size: 12, weight: .regular))
                    } else {
                        Text(detectedBank)
                            .font(.system(size: 12, weight: .regular))
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
                    Text(selectedBank == nil ? "SELECT BANK" : "CHANGE BANK")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(.tertiary)

                    Picker("Bank", selection: $state.selectedBankID) {
                        Text("Select Bank").tag(UUID?.none)
                        ForEach(banks) { bank in
                            Text(bank.name).tag(UUID?(bank.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
