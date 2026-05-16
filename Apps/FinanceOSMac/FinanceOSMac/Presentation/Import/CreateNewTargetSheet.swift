import FinanceCore
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
                Text(isCard ? "Create New Card" : "Create New Account")
                    .headingMedium()
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
                        Text("Basic Information")
                            .captionLarge()
                            .foregroundColor(.gray)

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
                        Text("Bank")
                            .captionLarge()
                            .foregroundColor(.gray)

                        VStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current Bank")
                                    .labelSmall()
                                    .foregroundColor(.gray)
                                HStack {
                                    if let bank = selectedBank {
                                        Text(bank.name)
                                            .caption()
                                    } else {
                                        Text(detectedBank)
                                            .caption()
                                    }
                                    Spacer()
                                }
                                .padding(AppSpacing.xs)
                                .background(AppColors.surface2)
                                .cornerRadius(AppRadius.sm)
                            }

                            if !banks.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(selectedBank == nil ? "Select Bank" : "Change Bank")
                                        .labelSmall()
                                        .foregroundColor(.gray)
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
                    Text("Cancel")
                        .bodyLarge()
                        .frame(maxWidth: .infinity)
                })
                .foregroundColor(.gray)
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .cornerRadius(AppRadius.md)

                Button(action: { onCreate() }, label: {
                    Text("Create")
                        .monoAmount()
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
            Text(label)
                .labelSmall()
                .foregroundColor(.gray)
            TextField("", text: text)
                .caption()
                .padding(AppSpacing.xs)
                .background(AppColors.surface2)
                .cornerRadius(AppRadius.sm)
        }
    }
}
