import FinanceCore
import SwiftUI

struct CreateNewTargetSheet: View {
    @Binding var name: String
    @Binding var nickname: String
    @Binding var last4: String
    @Binding var bankID: UUID?
    let isCard: Bool
    let banks: [Bank]
    let detectedBank: String
    let onCancel: () -> Void
    let onCreate: () -> Void

    var selectedBank: Bank? {
        guard let id = bankID else { return nil }
        return banks.first { $0.id == id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(isCard ? "Create New Card" : "Create New Account")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Button(action: { onCancel() }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
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
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)

                        VStack(spacing: 8) {
                            inputField("Name (Optional)", text: $name)

                            if isCard {
                                inputField("Nickname", text: $nickname)
                            }

                            inputField("Last 4 Digits", text: $last4)
                                .onChange(of: last4) { _, newValue in
                                    if newValue.count > 4 {
                                        last4 = String(newValue.prefix(4))
                                    }
                                }
                        }
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppRadius.md)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bank")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.gray)

                        VStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current Bank")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                                HStack {
                                    if let bank = selectedBank {
                                        Text(bank.name)
                                            .font(.system(size: 13, weight: .regular))
                                    } else {
                                        Text(detectedBank)
                                            .font(.system(size: 13, weight: .regular))
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
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.gray)
                                    Picker("Bank", selection: $bankID) {
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
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                })
                .foregroundColor(.gray)
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .cornerRadius(AppRadius.md)

                Button(action: { onCreate() }, label: {
                    Text("Create")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                })
                .padding(AppSpacing.sm)
                .background(AppColors.accent)
                .cornerRadius(AppRadius.md)
                .disabled(last4.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(AppSpacing.md)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.base)
    }

    private func inputField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.gray)
            TextField("", text: text)
                .font(.system(size: 13, weight: .regular))
                .padding(AppSpacing.xs)
                .background(AppColors.surface2)
                .cornerRadius(AppRadius.sm)
        }
    }
}
