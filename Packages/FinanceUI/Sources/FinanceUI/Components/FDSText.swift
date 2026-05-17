import FinanceCore
import SwiftUI

enum FDSTextStyle {
    case displayLarge
    case displayMedium
    case headingLarge
    case headingMedium
    case headingSmall
    case bodyLarge
    case bodyMedium
    case labelSmall
    case captionLarge
    case caption
    case monoAmount
    case monoAmountSmall
}

enum FDSTextColor {
    case primary
    case secondary
    case tertiary
    case debit
    case credit
    case warning
    case accent
    case custom(Color)

    var color: Color {
        switch self {
        case .primary:
            return AppColors.textPrimary
        case .secondary:
            return AppColors.textSecondary
        case .tertiary:
            return AppColors.textTertiary
        case .debit:
            return AppColors.debit
        case .credit:
            return AppColors.credit
        case .warning:
            return AppColors.warning
        case .accent:
            return AppColors.accent
        case .custom(let color):
            return color
        }
    }
}

struct FDSText: View {
    let text: String
    let style: FDSTextStyle
    let color: FDSTextColor

    var body: some View {
        Text(text)
            .applyStyle(style)
            .foregroundColor(color.color)
    }

    init(_ text: String, style: FDSTextStyle = .bodyLarge, color: FDSTextColor = .primary) {
        self.text = text
        self.style = style
        self.color = color
    }
}

private extension View {
    func applyStyle(_ style: FDSTextStyle) -> some View {
        switch style {
        case .displayLarge:
            return AnyView(self.displayLarge())
        case .displayMedium:
            return AnyView(self.displayMedium())
        case .headingLarge:
            return AnyView(self.headingLarge())
        case .headingMedium:
            return AnyView(self.headingMedium())
        case .headingSmall:
            return AnyView(self.headingSmall())
        case .bodyLarge:
            return AnyView(self.bodyLarge())
        case .bodyMedium:
            return AnyView(self.bodyMedium())
        case .labelSmall:
            return AnyView(self.labelSmall())
        case .captionLarge:
            return AnyView(self.captionLarge())
        case .caption:
            return AnyView(self.caption())
        case .monoAmount:
            return AnyView(self.font(.system(size: 14, weight: .semibold, design: .monospaced)).lineSpacing(0))
        case .monoAmountSmall:
            return AnyView(self.font(.system(size: 12, weight: .regular, design: .monospaced)).lineSpacing(0))
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        FDSText("Debit Amount", style: .monoAmount, color: .debit)
        FDSText("Credit Amount", style: .monoAmount, color: .credit)
        FDSText("Error Message", style: .caption, color: .warning)
        FDSText("Success", style: .headingSmall, color: .credit)
    }
    .padding()
}
