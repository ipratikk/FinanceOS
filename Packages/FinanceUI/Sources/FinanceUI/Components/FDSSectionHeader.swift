import FinanceCore
import SwiftUI

/// Visual-first section header. Subtle, hierarchical, calm.
///
/// Layout:
/// ```
/// SECTION LABEL                       [Action →]
/// Optional subtitle text muted
/// ```
public struct FDSSectionHeader: View {
    let title: String
    let subtitle: String?
    let actionLabel: String?
    let actionSymbol: String?
    let action: (() -> Void)?

    public init(
        _ title: String,
        subtitle: String? = nil,
        actionLabel: String? = nil,
        actionSymbol: String? = "chevron.right",
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionLabel = actionLabel
        self.actionSymbol = actionSymbol
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: AppSpacing.tight) {
                Text(title)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.captionSm)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if let actionLabel, let action {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text(actionLabel)
                            .font(AppTypography.captionLgMedium)
                        if let actionSymbol {
                            Image(systemName: actionSymbol)
                                .font(.system(size: 10, weight: .semibold))
                        }
                    }
                    .foregroundStyle(AppColors.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, AppSpacing.compact)
    }
}
