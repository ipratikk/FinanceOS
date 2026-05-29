import FinanceCore
import SwiftUI

/// Typography scale applied by `FDSTextInput`.
public enum FDSTextInputStyle {
    case bodyLarge
    case bodyMedium
    case labelSmall
}

/// Bare TextField/SecureField with FDS typography. No chrome — rely on a wrapping
/// `FDSField` or `FDSInputField` for label, border, and error display.
public struct FDSTextInput: View {
    @Binding var text: String
    let placeholder: String
    let style: FDSTextInputStyle
    let isSecure: Bool

    public var body: some View {
        if isSecure {
            SecureField(placeholder, text: $text)
                .applyInputStyle(style)
        } else {
            TextField(placeholder, text: $text)
                .applyInputStyle(style)
        }
    }

    public init(
        _ placeholder: String,
        text: Binding<String>,
        style: FDSTextInputStyle = .bodyMedium,
        isSecure: Bool = false
    ) {
        self.placeholder = placeholder
        _text = text
        self.style = style
        self.isSecure = isSecure
    }
}

private extension View {
    func applyInputStyle(_ style: FDSTextInputStyle) -> some View {
        switch style {
        case .bodyLarge:
            return AnyView(font(AppTypography.bodyLg))
        case .bodyMedium:
            return AnyView(font(AppTypography.bodyMd))
        case .labelSmall:
            return AnyView(font(AppTypography.captionLgMedium))
        }
    }
}

#Preview {
    @Previewable @State var password = ""
    @Previewable @State var text = ""

    return VStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
            FDSLabel("Name")
                .font(AppTypography.captionSm)
                .foregroundStyle(AppColors.Text.primary)
            FDSTextInput("Enter name", text: $text, style: .bodyMedium)
                .textFieldStyle(.roundedBorder)
        }

        VStack(alignment: .leading, spacing: 4) {
            FDSLabel("Password")
                .font(AppTypography.captionSm)
                .foregroundStyle(AppColors.Text.primary)
            FDSTextInput("Enter password", text: $password, style: .bodyMedium, isSecure: true)
                .textFieldStyle(.roundedBorder)
        }
    }
    .padding()
}
