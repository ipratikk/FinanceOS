import FinanceCore
import SwiftUI

/// Recessed text input field with optional prefix/suffix.
///
/// 34pt height, black well background, 8pt radius, inset shadow.
/// Focus: 3pt accent ring. Optional mono digits or prefix/suffix.
public struct FDSInput: View {
    let placeholder: String
    @Binding var text: String
    let prefix: String?
    let suffix: String?
    let isMono: Bool
    let isSecure: Bool

    @FocusState private var isFocused

    public init(
        _ placeholder: String = "",
        text: Binding<String>,
        prefix: String? = nil,
        suffix: String? = nil,
        isMono: Bool = false,
        isSecure: Bool = false
    ) {
        self.placeholder = placeholder
        _text = text
        self.prefix = prefix
        self.suffix = suffix
        self.isMono = isMono
        self.isSecure = isSecure
    }

    public var body: some View {
        HStack(spacing: 8) {
            if let prefix {
                Text(prefix)
                    .font(.system(size: 13, weight: .regular, design: isMono ? .monospaced : .default))
                    .foregroundColor(AppColors.textTertiary)
            }

            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 14, weight: .regular, design: isMono ? .monospaced : .default))
                    .focused($isFocused)
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 14, weight: .regular, design: isMono ? .monospaced : .default))
                    .focused($isFocused)
            }

            if let suffix {
                Text(suffix)
                    .font(.system(size: 12, weight: .regular, design: isMono ? .monospaced : .default))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(AppColors.surface2)
        .cornerRadius(8)
        .overlay {
            if isFocused {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        AppColors.accent.opacity(0.5),
                        lineWidth: 2
                    )
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        FDSInput("Enter name", text: .constant("Savings"))

        FDSInput("Balance", text: .constant("50000"), prefix: "₹", isMono: true)

        FDSInput("Last 4", text: .constant("1234"), isMono: true)
    }
    .padding()
}
