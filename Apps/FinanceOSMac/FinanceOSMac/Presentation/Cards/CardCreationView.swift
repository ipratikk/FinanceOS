import FinanceCore
import FinanceUI
import SwiftUI

struct CardCreationView: View {
    let state: TargetCreationState
    let onCommit: (TargetCreationState) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var nickname: String
    @State private var cardType: CardNetwork
    @State private var last4: String

    init(state: TargetCreationState, onCommit: @escaping (TargetCreationState) -> Void) {
        self.state = state
        self.onCommit = onCommit
        _nickname = State(initialValue: state.nickname)
        _cardType = State(initialValue: state.cardType)
        _last4 = State(initialValue: state.last4)
    }

    var body: some View {
        FDSSheet(
            title: "Create Card",
            subtitle: state.customName,
            onDismiss: { dismiss() },
            content: {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    FDSCard(cornerRadius: 12, padded: false) {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            FDSLabel("CARD DETAILS")
                                .font(AppTypography.captionSmSemibold)
                                .tracking(0.2)
                                .foregroundColor(DesignTokens.Text.secondary)

                            fieldInput("Nickname", text: $nickname)
                            Divider().opacity(DesignTokens.Opacity.low)
                            fieldInput("Card Type", cardNetwork: $cardType)
                            Divider().opacity(DesignTokens.Opacity.low)
                            fieldInput("Last 4 Digits", text: $last4)
                        }
                        .padding(AppSpacing.xs)
                    }

                    Button(action: commit) {
                        FDSLabel("Create Card")
                            .font(AppTypography.bodySmSemibold)
                            .frame(maxWidth: .infinity)
                            .padding(AppSpacing.xs)
                            .background(AppColors.accentBlue)
                            .foregroundColor(AppColors.textPrimary)
                            .cornerRadius(6)
                    }
                }
            }
        )
    }

    private func commit() {
        var updatedState = state
        updatedState.nickname = nickname
        updatedState.cardType = cardType
        updatedState.last4 = last4
        onCommit(updatedState)
        dismiss()
    }

    private func fieldInput(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            FDSLabel(label.uppercased())
                .font(AppTypography.captionSmSemibold)
                .tracking(0.2)
                .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
            FDSTextInput("", text: text, style: .labelSmall)
                .foregroundColor(DesignTokens.Text.primary)
                .padding(8)
                .background(DesignTokens.Background.inputWell)
                .cornerRadius(6)
        }
    }

    private func fieldInput(_ label: String, cardNetwork: Binding<CardNetwork>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            FDSLabel(label.uppercased())
                .font(AppTypography.captionSmSemibold)
                .tracking(0.2)
                .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
            Picker("", selection: cardNetwork) {
                ForEach(CardNetwork.allCases, id: \.self) { network in
                    FDSLabel(network.rawValue).tag(network)
                }
            }
            .pickerStyle(.segmented)
            .frame(height: 32)
        }
    }
}
