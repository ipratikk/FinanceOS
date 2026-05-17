import FinanceCore
import SwiftUI

public struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionLabel: String?

    public init(_ title: String, subtitle: String? = nil, action: (() -> Void)? = nil, actionLabel: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.actionLabel = actionLabel
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(title)
                    .headingMedium()

                if let subtitle {
                    Text(subtitle)
                        .caption()
                }
            }

            Spacer()

            if let action, let actionLabel {
                Button(action: action) {
                    Text(actionLabel)
                        .captionLarge()
                        .foregroundColor(AppColors.accent)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        SectionHeader("Recent Transactions")
        SectionHeader(
            "Accounts",
            subtitle: "3 linked accounts",
            action: { print("View All") },
            actionLabel: "View All →"
        )
    }
    .padding(AppSpacing.lg)
    .background(AppColors.base)
}
