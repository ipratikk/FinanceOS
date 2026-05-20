import FinanceCore
import SwiftUI

/// Inline persistent banner for status messages.
///
/// Unlike Toast (ephemeral, auto-dismiss), FDSBanner is persistent and
/// lives in the view hierarchy — suitable for import feedback, warnings,
/// and contextual alerts.
///
/// Styles: `.info`, `.success`, `.warning`, `.error`, `.neutral`
public enum FDSBannerStyle {
    case info, success, warning, error, neutral
}

public struct FDSBanner: View {
    let message: String
    let style: FDSBannerStyle
    let onDismiss: (() -> Void)?

    public init(
        _ message: String,
        style: FDSBannerStyle = .info,
        onDismiss: (() -> Void)? = nil
    ) {
        self.message = message
        self.style = style
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(AppTypography.bodySmSemibold)
                .foregroundStyle(tintColor)

            FDSLabel(message)
                .font(AppTypography.captionLgMedium)
                .foregroundStyle(DesignTokens.Text.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(AppTypography.captionSmSemibold)
                        .foregroundStyle(DesignTokens.Text.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(tintColor.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .stroke(tintColor.opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(AppRadius.sm)
    }

    private var tintColor: Color {
        switch style {
        case .info: return AppColors.info
        case .success: return AppColors.success
        case .warning: return AppColors.warning
        case .error: return AppColors.danger
        case .neutral: return DesignTokens.Text.tertiary
        }
    }

    private var icon: String {
        switch style {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .neutral: return "circle.fill"
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.sm) {
        FDSBanner("3 transactions imported successfully.", style: .success)
        FDSBanner("2 rows skipped — duplicate fingerprints detected.", style: .warning, onDismiss: {})
        FDSBanner("Could not parse date in row 14. Check file format.", style: .error, onDismiss: {})
        FDSBanner("Statement period: Jan 2025 – Mar 2025.", style: .info)
        FDSBanner("Showing cached data. Last updated 3 hours ago.", style: .neutral, onDismiss: {})
    }
    .padding(AppSpacing.xl)
    .background(AppColors.base)
}
