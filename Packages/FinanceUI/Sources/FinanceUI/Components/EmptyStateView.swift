import FinanceCore
import SwiftUI

public struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: (() -> Void)?
    let actionLabel: String?

    public init(
        icon: String,
        title: String,
        subtitle: String,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.actionLabel = actionLabel
    }

    public var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(AppTypography.custom(size: 48, weight: .light))
                .foregroundColor(AppColors.textTertiary)

            VStack(spacing: AppSpacing.sm) {
                FDSLabel(title)
                    .headingMedium()

                FDSLabel(subtitle)
                    .bodyMedium()
            }

            if let action, let actionLabel {
                Button(action: action, label: {
                    FDSLabel(actionLabel)
                        .bodyLarge()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.accent)
                        .foregroundColor(AppColors.textPrimary)
                        .cornerRadius(AppRadius.md)
                })
            }
        }
        .padding(AppSpacing.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

#Preview {
    VStack {
        EmptyStateView(
            icon: "inbox.fill",
            title: "No Transactions",
            subtitle: "Import a statement to get started",
            action: { print("Import") },
            actionLabel: "Import Statement"
        )
    }
    .background(AppColors.base)
}
