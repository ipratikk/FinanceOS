import FinanceCore
import SwiftUI

/// Compact account/card reference chip.
///
/// Renders as: [bank logo · last 4]
/// Use for inline references (transaction source, filter pills, account selectors).
public struct FDSAccountChip: View {
    let bankName: String
    let last4: String
    let bankLogoName: String?
    let style: Style

    public enum Style {
        case compact // dense, inline
        case prominent // standalone, larger
    }

    public init(
        bankName: String,
        last4: String,
        bankLogoName: String? = nil,
        style: Style = .compact
    ) {
        self.bankName = bankName
        self.last4 = last4
        self.bankLogoName = bankLogoName
        self.style = style
    }

    public var body: some View {
        HStack(spacing: spacing) {
            FDSMerchantAvatar(
                name: bankName,
                symbol: "building.columns.fill",
                imageName: bankLogoName,
                size: avatarSize
            )

            VStack(alignment: .leading, spacing: 0) {
                Text(bankName)
                    .font(nameFont)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if !last4.isEmpty {
                    Text("•••• \(last4)")
                        .font(last4Font)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, padding)
        .padding(.vertical, padding * 0.6)
        .background {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
        }
    }

    private var avatarSize: CGFloat {
        switch style {
        case .compact:
            22
        case .prominent:
            32
        }
    }

    private var spacing: CGFloat {
        switch style {
        case .compact:
            AppSpacing.compact
        case .prominent:
            AppSpacing.md
        }
    }

    private var padding: CGFloat {
        switch style {
        case .compact:
            AppSpacing.compact
        case .prominent:
            AppSpacing.md
        }
    }

    private var nameFont: Font {
        switch style {
        case .compact:
            .system(size: 12, weight: .medium)
        case .prominent:
            .system(size: 14, weight: .semibold)
        }
    }

    private var last4Font: Font {
        switch style {
        case .compact:
            .system(size: 10, weight: .regular).monospacedDigit()
        case .prominent:
            .system(size: 12, weight: .regular).monospacedDigit()
        }
    }
}
