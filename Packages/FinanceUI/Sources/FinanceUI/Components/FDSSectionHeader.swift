import FinanceCore
import SwiftUI

/// Visual-first section header. Subtle, hierarchical, calm.
///
/// Two inits:
/// - `init(_:subtitle:actionLabel:actionSymbol:action:)` — convenience for a single text button trailing
/// - `init(_:subtitle:trailing:)` — ViewBuilder for arbitrary trailing content
public struct FDSSectionHeader: View {
    let title: String
    let subtitle: String?
    private let trailingView: AnyView?

    // MARK: - Text action init (backward compat)

    public init(
        _ title: String,
        subtitle: String? = nil,
        actionLabel: String? = nil,
        actionSymbol: String? = "chevron.right",
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        if let actionLabel, let action {
            trailingView = AnyView(
                Button(action: action) {
                    HStack(spacing: 4) {
                        FDSLabel(actionLabel)
                            .font(AppTypography.captionLgMedium)
                        if let actionSymbol {
                            Image(systemName: actionSymbol)
                                .font(AppTypography.captionLgSemibold)
                        }
                    }
                    .foregroundStyle(AppColors.accent)
                }
                .buttonStyle(.plain)
            )
        } else {
            trailingView = nil
        }
    }

    // MARK: - ViewBuilder trailing init

    /// Use this init for arbitrary trailing content (e.g. filter chips, icon buttons).
    public init(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> some View
    ) {
        self.title = title
        self.subtitle = subtitle
        trailingView = AnyView(trailing())
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: AppSpacing.tight) {
                FDSLabel(title)
                    .font(AppTypography.headingMd)
                    .foregroundStyle(AppColors.Text.primary)

                if let subtitle {
                    FDSLabel(subtitle)
                        .font(AppTypography.captionLg)
                        .foregroundStyle(AppColors.Text.tertiary)
                }
            }

            Spacer()

            trailingView
        }
        .padding(.vertical, AppSpacing.compact)
    }
}
