import FinanceCore
import FinanceUI
import SwiftUI

struct AccountCreationView: View {
    let state: TargetCreationState
    let onCommit: (TargetCreationState) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var nickname: String
    @State private var last4: String
    @State private var accountType: String

    private let accountTypeOptions = ["savings", "checking", "money_market", "other"]

    init(state: TargetCreationState, onCommit: @escaping (TargetCreationState) -> Void) {
        self.state = state
        self.onCommit = onCommit
        _nickname = State(initialValue: state.nickname)
        _last4 = State(initialValue: state.last4)
        _accountType = State(initialValue: state.accountType.isEmpty ? "savings" : state.accountType)
    }

    var body: some View {
        FDSSheet(
            title: "Create Account",
            subtitle: state.customName,
            onDismiss: { dismiss() },
            content: {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    FDSCard(padded: false) {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            FDSLabel("ACCOUNT DETAILS")
                                .font(AppTypography.captionSmSemibold)
                                .tracking(0.2)
                                .foregroundColor(AppColors.Text.secondary)

                            fieldInput("Nickname", text: $nickname)
                            Divider().opacity(AppColors.Opacity.low)
                            fieldInput("Last 4 Digits", text: $last4)
                                .onChange(of: last4) { _, newValue in
                                    if newValue.count > 4 { last4 = String(newValue.prefix(4)) }
                                }
                        }
                        .padding(AppSpacing.xs)
                    }

                    FDSCard(padded: false) {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            FDSLabel("ACCOUNT TYPE")
                                .font(AppTypography.captionSmSemibold)
                                .tracking(0.2)
                                .foregroundColor(AppColors.Text.secondary)

                            FDSChoiceGroup(
                                selection: $accountType,
                                options: accountTypeOptions,
                                optionLabel: { accountTypeLabel($0) }
                            )
                        }
                        .padding(AppSpacing.xs)
                    }

                    FDSLiquidButton("Create Account", leadingIcon: "plus", variant: .primary) {
                        commit()
                    }
                    .disabled(last4.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        )
    }

    private func commit() {
        var updatedState = state
        updatedState.nickname = nickname
        updatedState.last4 = last4
        updatedState.accountType = accountType
        onCommit(updatedState)
        dismiss()
    }

    private func accountTypeLabel(_ type: String) -> String {
        switch type {
        case "savings": return "Savings"
        case "checking": return "Checking"
        case "money_market": return "Money Mkt"
        case "other": return "Other"
        default: return type.capitalized
        }
    }

    private func fieldInput(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            FDSLabel(label.uppercased())
                .font(AppTypography.captionSmSemibold)
                .tracking(0.2)
                .foregroundColor(AppColors.Text.secondary)
            FDSTextInput("", text: text, style: .labelSmall)
                .foregroundColor(AppColors.Text.primary)
                .padding(8)
                .background(AppColors.Glass.inputWell)
                .cornerRadius(AppRadius.sm)
        }
    }
}
