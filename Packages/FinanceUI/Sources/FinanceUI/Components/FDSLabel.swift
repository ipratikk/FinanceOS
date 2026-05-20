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
        font(style.font)
            .lineSpacing(style.lineSpacing)
    }
}

private extension FDSLabelStyle {
    var font: Font {
        switch self {
        case .displayLarge:
            return AppTypography.displayLarge
        case .displayMedium:
            return .system(size: 28, weight: .bold)
        case .headingLarge:
            return AppTypography.headingXL
        case .heading:
            return AppTypography.headingXL
        case .headingMedium:
            return AppTypography.headingLg
        case .headingSmall:
            return AppTypography.headingSmall
        case .subheading:
            return AppTypography.headingSmall
        case .bodyLarge:
            return AppTypography.bodyLg
        case .bodyMedium:
            return AppTypography.bodyMd
        case .labelSmall:
            return AppTypography.captionLgMedium
        case .captionLarge:
            return AppTypography.captionLg
        case .caption:
            return .system(size: 10, weight: .regular)
        case .hint:
            return .system(size: 10, weight: .regular)
        case .monoAmount:
            return .system(size: 14, weight: .semibold, design: .monospaced)
        case .monoAmountSmall:
            return .system(size: 12, weight: .regular, design: .monospaced)
        }
    }

    var lineSpacing: CGFloat {
        switch self {
        case .displayLarge, .displayMedium:
            return 2
        case .headingLarge, .heading, .headingMedium, .bodyLarge, .bodyMedium:
            return 1.5
        case .headingSmall, .subheading:
            return 1
        case .labelSmall, .captionLarge, .caption, .hint, .monoAmount, .monoAmountSmall:
            return 0
        }
    }
}
