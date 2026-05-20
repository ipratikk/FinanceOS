import FinanceCore
import SwiftUI

public struct Toast: Identifiable {
    public let id: UUID
    public let message: String
    public let type: ToastType
    public let duration: TimeInterval

    public enum ToastType {
        case success
        case error
        case warning
        case info
    }

    public init(
        message: String,
        type: ToastType = .info,
        duration: TimeInterval = 4.0
    ) {
        id = UUID()
        self.message = message
        self.type = type
        self.duration = duration
    }
}

public struct ToastView: View {
    let toast: Toast

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: iconName)
                .font(AppTypography.custom(size: 16, weight: .semibold))
                .foregroundColor(iconColor)

            FDSLabel(toast.message)
                .font(AppTypography.labelMedium)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(backgroundColor)
        .cornerRadius(AppRadius.sm)
    }

    private var iconName: String {
        switch toast.type {
        case .success: "checkmark.circle.fill"
        case .error: "xmark.circle.fill"
        case .warning: "exclamationmark.circle.fill"
        case .info: "info.circle.fill"
        }
    }

    private var iconColor: Color {
        switch toast.type {
        case .success: AppColors.credit
        case .error: AppColors.danger
        case .warning: AppColors.warning
        case .info: AppColors.info
        }
    }

    private var backgroundColor: Color {
        switch toast.type {
        case .success: AppColors.credit.opacity(0.9)
        case .error: AppColors.danger.opacity(0.9)
        case .warning: AppColors.warning.opacity(0.9)
        case .info: AppColors.info.opacity(0.9)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ToastView(toast: Toast(message: "Import successful", type: .success))
        ToastView(toast: Toast(message: "Something went wrong", type: .error))
        ToastView(toast: Toast(message: "Check your input", type: .warning))
        ToastView(toast: Toast(message: "FYI: This is informational", type: .info))
    }
    .padding()
    .background(AppColors.base)
}
