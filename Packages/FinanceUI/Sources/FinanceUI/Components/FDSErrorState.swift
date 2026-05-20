import FinanceCore
import SwiftUI

/// Standard error state component for all async operations.
/// Replaces ad-hoc error handling throughout the app.
public struct FDSErrorState: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    public init(
        title: String,
        message: String,
        actionTitle: String = "Retry",
        action: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(AppTypography.displayLargeLight)
                .foregroundColor(.orange)

            FDSLabel(title)
                .font(AppTypography.headingMd)
                .foregroundColor(.primary)

            FDSLabel(message)
                .font(AppTypography.bodyMd)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.center)

            Button(action: action, label: {
                FDSLabel(actionTitle)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.md)
                    .background(AppColors.accentBlue)
                    .foregroundColor(AppColors.textPrimary)
                    .cornerRadius(8)
            })
        }
        .padding(AppSpacing.xl)
    }
}

// MARK: - Preview

#Preview {
    FDSErrorState(
        title: "Failed to Load Accounts",
        message: "There was an error connecting to the database. Please check your connection and try again.",
        actionTitle: "Retry",
        action: {}
    )
}
