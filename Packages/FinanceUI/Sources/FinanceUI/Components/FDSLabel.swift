import FinanceCore
import SwiftUI

public enum FDSLabelStyle {
    case displayLarge
    case displayMedium
    case headingLarge
    case headingMedium
    case headingSmall
    case heading
    case subheading
    case bodyLarge
    case bodyMedium
    case labelSmall
    case captionLarge
    case caption
    case hint
    case monoAmount
    case monoAmountSmall
}

public enum FDSLabelColor {
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

public struct FDSLabel: View {
    let text: String
    let style: FDSLabelStyle
    let color: FDSLabelColor

    public var body: some View {
        Text(text)
            .applyLabelStyle(style)
            .foregroundColor(color.color)
    }

    public init(_ text: String, style: FDSLabelStyle = .caption, color: FDSLabelColor = .primary) {
        self.text = text
        self.style = style
        self.color = color
    }
}

private extension View {
    func applyLabelStyle(_ style: FDSLabelStyle) -> some View {
        switch style {
        case .displayLarge:
            return AnyView(font(.system(size: 34, weight: .bold)).lineSpacing(2))
        case .displayMedium:
            return AnyView(font(.system(size: 28, weight: .bold)).lineSpacing(2))
        case .headingLarge:
            return AnyView(font(.system(size: 24, weight: .bold)).lineSpacing(1.5))
        case .heading:
            return AnyView(font(.system(size: 24, weight: .bold)).lineSpacing(1.5))
        case .headingMedium:
            return AnyView(font(.system(size: 20, weight: .semibold)).lineSpacing(1.5))
        case .headingSmall:
            return AnyView(font(.system(size: 16, weight: .semibold)).lineSpacing(1))
        case .subheading:
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
        case .hint:
            return AnyView(font(.system(size: 10, weight: .regular)).lineSpacing(0))
        case .monoAmount:
            return AnyView(font(.system(size: 14, weight: .semibold, design: .monospaced)).lineSpacing(0))
        case .monoAmountSmall:
            return AnyView(font(.system(size: 12, weight: .regular, design: .monospaced)).lineSpacing(0))
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        FDSLabel("Display Large", style: .displayLarge)
        FDSLabel("Heading", style: .headingLarge)
        FDSLabel("Body", style: .bodyLarge)
        FDSLabel("Caption", style: .caption)
        FDSLabel("Error Message", style: .caption, color: .warning)
        FDSLabel("Success", style: .headingSmall, color: .credit)
    }
    .padding()
}
