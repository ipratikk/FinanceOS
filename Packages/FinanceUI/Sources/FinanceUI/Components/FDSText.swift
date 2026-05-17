import FinanceCore
import SwiftUI

public enum FDSTextStyle {
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

public enum FDSTextColor {
    case primary
    case secondary
    case tertiary
    case debit
    case credit
    case warning
    case accent
    case custom(Color)

    public var color: Color {
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
        case let .custom(color):
            return color
        }
    }
}

public struct FDSText: View {
    let text: String
    let style: FDSTextStyle
    let color: FDSTextColor

    public var body: some View {
        Text(text)
            .applyStyle(style)
            .foregroundColor(color.color)
    }

    public init(_ text: String, style: FDSTextStyle = .bodyLarge, color: FDSTextColor = .primary) {
        self.text = text
        self.style = style
        self.color = color
    }
}

private extension View {
    func applyStyle(_ style: FDSTextStyle) -> some View {
        switch style {
        case .displayLarge:
            return AnyView(font(.system(size: 34, weight: .bold)).lineSpacing(2))
        case .displayMedium:
            return AnyView(font(.system(size: 28, weight: .bold)).lineSpacing(2))
        case .headingLarge:
            return AnyView(font(.system(size: 24, weight: .bold)).lineSpacing(1.5))
        case .headingMedium:
            return AnyView(font(.system(size: 20, weight: .semibold)).lineSpacing(1.5))
        case .headingSmall:
            return AnyView(font(.system(size: 16, weight: .semibold)).lineSpacing(1))
        case .bodyLarge:
            return AnyView(font(.system(size: 16, weight: .regular)).lineSpacing(1.5))
        case .bodyMedium:
            return AnyView(font(.system(size: 14, weight: .regular)).lineSpacing(1.5))
        case .labelSmall:
            return AnyView(font(.system(size: 12, weight: .medium)).lineSpacing(0))
        case .captionLarge:
            return AnyView(font(.system(size: 12, weight: .regular)).lineSpacing(0))
        case .caption:
            return AnyView(font(.system(size: 10, weight: .regular)).lineSpacing(0))
        case .monoAmount:
            return AnyView(font(.system(size: 14, weight: .semibold, design: .monospaced)).lineSpacing(0))
        case .monoAmountSmall:
            return AnyView(font(.system(size: 12, weight: .regular, design: .monospaced)).lineSpacing(0))
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
