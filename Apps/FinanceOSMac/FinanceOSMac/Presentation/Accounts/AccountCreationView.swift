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

    init(state: TargetCreationState, onCommit: @escaping (TargetCreationState) -> Void) {
        self.state = state
        self.onCommit = onCommit
        _nickname = State(initialValue: state.nickname)
        _last4 = State(initialValue: state.last4)
        _accountType = State(initialValue: state.accountType)
    }

    var body: some View {
        FDSSheet(
            title: "Create Account",
            subtitle: state.customName,
            onDismiss: { dismiss() }
        ) {
            VStack(alignment: .leading, spacing: 20) {
                FDSCard(cornerRadius: 12, padded: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ACCOUNT DETAILS")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.2)
                            .foregroundColor(DesignTokens.Text.secondary)

                        fieldInput("Nickname", text: $nickname)
                        Divider().opacity(DesignTokens.Opacity.low)
                        fieldInput("Account Type", text: $accountType)
                        Divider().opacity(DesignTokens.Opacity.low)
                        fieldInput("Last 4 Digits", text: $last4)
                    }
                    .padding(12)
                }

                Button(action: commit) {
                    Text("Create Account")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }
        }
    }

    private func commit() {
        var updatedState = state
        updatedState.nickname = nickname
        updatedState.last4 = last4
        updatedState.accountType = accountType
        onCommit(updatedState)
        dismiss()
    }

    private func fieldInput(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.2)
                .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
            FDSTextInput("", text: text, style: .labelSmall)
                .foregroundColor(DesignTokens.Text.primary)
                .padding(8)
                .background(DesignTokens.Background.inputWell)
                .cornerRadius(6)
        }
    }
}
