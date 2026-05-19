import FinanceCore
import SwiftUI

public enum FDSTextInputStyle {
    case bodyLarge
    case bodyMedium
    case labelSmall
}

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
            return AnyView(font(.system(size: 16, weight: .regular)))
        case .bodyMedium:
            return AnyView(font(.system(size: 14, weight: .regular)))
        case .labelSmall:
            return AnyView(font(.system(size: 12, weight: .medium)))
        }
    }
}

#Preview {
    @State var password = ""
    @State var text = ""

    return VStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
            FDSLabel("Name", style: .caption)
            FDSTextInput("Enter name", text: $text, style: .bodyMedium)
                .textFieldStyle(.roundedBorder)
        }

        VStack(alignment: .leading, spacing: 4) {
            FDSLabel("Password", style: .caption)
            FDSTextInput("Enter password", text: $password, style: .bodyMedium, isSecure: true)
                .textFieldStyle(.roundedBorder)
        }
    }
    .padding()
}
