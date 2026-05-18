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
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            Text(message)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.center)

            Button(action: action) {
                Text(actionTitle)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(24)
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
