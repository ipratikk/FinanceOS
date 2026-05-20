import FinanceCore
import SwiftUI

/// Input field with label, validation state, and helper/error messaging.
///
/// States:
/// - `.normal` — default, shows optional helper text in tertiary color
/// - `.error(String)` — red border + error message below
/// - `.success` — green border, shows helper text if present
public enum FDSInputState: Equatable {
    case normal
    case error(String)
    case success
}

public struct FDSInputField: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    let helper: String?
    let state: FDSInputState
    let isSecure: Bool

    public init(
        _ label: String,
        text: Binding<String>,
        placeholder: String = "",
        helper: String? = nil,
        state: FDSInputState = .normal,
        isSecure: Bool = false
    ) {
        self.label = label
        _text = text
        self.placeholder = placeholder
        self.helper = helper
        self.state = state
        self.isSecure = isSecure
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.tight) {
            FDSLabel(label)
                .font(AppTypography.captionSmSemibold)
                .foregroundStyle(DesignTokens.Text.secondary)

            FDSTextInput(placeholder, text: $text, isSecure: isSecure)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.compact)
                .background(DesignTokens.Background.inputWell)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .stroke(borderColor, lineWidth: 1)
                )
                .cornerRadius(AppRadius.sm)

            if let message = statusMessage {
                FDSLabel(message)
                    .font(AppTypography.captionSm)
                    .foregroundStyle(messageColor)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(AppAnimation.easeSmooth, value: state)
    }

    private var borderColor: Color {
        switch state {
        case .normal: return DesignTokens.Border.subtle
        case .error: return AppColors.danger.opacity(0.5)
        case .success: return AppColors.success.opacity(0.5)
        }
    }

    private var statusMessage: String? {
        switch state {
        case .normal, .success: return helper
        case let .error(msg): return msg
        }
    }

    private var messageColor: Color {
        switch state {
        case .normal, .success: return DesignTokens.Text.tertiary
        case .error: return AppColors.danger
        }
    }
}

#Preview {
    @Previewable @State var name = ""
    @Previewable @State var password = ""

    return VStack(spacing: AppSpacing.lg) {
        FDSInputField(
            "Account name",
            text: $name,
            placeholder: "e.g. HDFC Savings",
            helper: "Used to identify this account"
        )
        FDSInputField(
            "Password",
            text: $password,
            placeholder: "Enter password",
            state: .error("Password is required"),
            isSecure: true
        )
        FDSInputField(
            "IFSC code",
            text: .constant("HDFC0001234"),
            placeholder: "HDFC0001234",
            state: .success
        )
    }
    .padding(AppSpacing.xl)
    .background(AppColors.base)
}
