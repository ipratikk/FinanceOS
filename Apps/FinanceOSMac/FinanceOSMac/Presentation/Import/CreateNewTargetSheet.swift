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
                        .foregroundColor(.gray)
                })
            }
            .padding(AppSpacing.md)
            .background(AppColors.base)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        FDSLabel("Basic Information", style: .subheading)

                        VStack(spacing: 8) {
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
                                VStack(alignment: .leading, spacing: 8) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            FDSLabel("Card Type", style: .hint)
                                            Spacer()
                                            Button(action: { autoDetectCardType() }) {
                                                FDSLabel("Auto-detect", style: .caption, color: .secondary)
                                            }
                                            .disabled(state.last4.trimmingCharacters(in: .whitespaces).count < 4)
                                        }
                                        Picker("Type", selection: $state.cardType) {
                                            Text("Visa").tag("visa")
                                            Text("Mastercard").tag("mastercard")
                                            Text("American Express").tag("amex")
                                            Text("Discover").tag("discover")
                                            Text("Diners Club").tag("diners")
                                            Text("Other").tag("other")
                                        }
                                        .pickerStyle(.menu)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(AppSpacing.xs)
                                    .background(AppColors.surface2)
                                    .cornerRadius(AppRadius.sm)

                                    Button(action: { showCardSelection = true }) {
                                        HStack {
                                            Image(systemName: "creditcard.fill")
                                                .labelSmall()
                                            FDSLabel("Browse Card Database", style: .bodyMedium)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .labelSmall()
                                        }
                                        .foregroundColor(AppColors.accent)
                                        .padding(AppSpacing.xs)
                                    }
                                }
                            }

                            if !isCard {
                                VStack(alignment: .leading, spacing: 4) {
                                    FDSLabel("Account Type", style: .hint)
                                    Picker("Type", selection: $state.accountType) {
                                        Text("Savings").tag("savings")
                                        Text("Checking").tag("checking")
                                        Text("Money Market").tag("money_market")
                                        Text("Other").tag("other")
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(AppSpacing.xs)
                                .background(AppColors.surface2)
                                .cornerRadius(AppRadius.sm)
                            }
                        }
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppRadius.md)

                    VStack(alignment: .leading, spacing: 8) {
                        FDSLabel("Bank", style: .subheading)

                        VStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                FDSLabel("Current Bank", style: .hint)
                                HStack {
                                    if let bank = selectedBank {
                                        FDSLabel(bank.name, style: .caption)
                                    } else {
                                        FDSLabel(detectedBank, style: .caption)
                                    }
                                    Spacer()
                                }
                                .padding(AppSpacing.xs)
                                .background(AppColors.surface2)
                                .cornerRadius(AppRadius.sm)
                            }

                            if !banks.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    FDSLabel(
                                        selectedBank == nil ? "Select Bank" : "Change Bank",
                                        style: .labelSmall,
                                        color: .secondary
                                    )
                                    Picker("Bank", selection: $state.selectedBankID) {
                                        Text("Select Bank").tag(UUID?.none)
                                        ForEach(banks) { bank in
                                            Text(bank.name).tag(UUID?(bank.id))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(AppSpacing.xs)
                                .background(AppColors.surface2)
                                .cornerRadius(AppRadius.sm)
                            }
                        }
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppRadius.md)
                }
                .padding(AppSpacing.md)
            }

            Divider()

            HStack(spacing: 12) {
                Button(action: { onCancel() }, label: {
                    FDSLabel("Cancel", style: .bodyLarge)
                        .frame(maxWidth: .infinity)
                })
                .foregroundColor(.gray)
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .cornerRadius(AppRadius.md)

                Button(action: { onCreate() }, label: {
                    FDSLabel("Create", style: .monoAmount)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                })
                .padding(AppSpacing.sm)
                .background(AppColors.accent)
                .cornerRadius(AppRadius.md)
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
                    state.cardProduct = card.name
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
}
