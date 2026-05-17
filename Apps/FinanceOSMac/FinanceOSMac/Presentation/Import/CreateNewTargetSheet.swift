import FinanceCore
import FinanceUI
import SwiftUI

struct CreateNewTargetSheet: View {
    @Binding var state: TargetCreationState
    let banks: [Bank]
    let detectedBank: String
    let onCancel: () -> Void
    let onCreate: () -> Void

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
                FDSText(isCard ? "Create New Card" : "Create New Account", style: .headingMedium)
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
                        FDSText("Basic Information", style: .captionLarge, color: .secondary)

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
                        }
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppRadius.md)

                    VStack(alignment: .leading, spacing: 8) {
                        FDSText("Bank", style: .captionLarge, color: .secondary)

                        VStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                FDSText("Current Bank", style: .labelSmall, color: .secondary)
                                HStack {
                                    if let bank = selectedBank {
                                        FDSText(bank.name, style: .caption)
                                    } else {
                                        FDSText(detectedBank, style: .caption)
                                    }
                                    Spacer()
                                }
                                .padding(AppSpacing.xs)
                                .background(AppColors.surface2)
                                .cornerRadius(AppRadius.sm)
                            }

                            if !banks.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    FDSText(
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
                    FDSText("Cancel", style: .bodyLarge)
                        .frame(maxWidth: .infinity)
                })
                .foregroundColor(.gray)
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .cornerRadius(AppRadius.md)

                Button(action: { onCreate() }, label: {
                    FDSText("Create", style: .monoAmount)
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
    }

    private func inputField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            FDSText(label, style: .labelSmall, color: .secondary)
            TextField("", text: text)
                .caption()
                .padding(AppSpacing.xs)
                .background(AppColors.surface2)
                .cornerRadius(AppRadius.sm)
        }
    }
}
