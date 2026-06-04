import FinanceCore
import SwiftUI

public enum NarrativeSeverity: Sendable {
    case info, warning, alert
}

public struct InsightNarrativeCard: View {
    public let text: String
    public let severity: NarrativeSeverity

    public init(text: String, severity: NarrativeSeverity) {
        self.text = text
        self.severity = severity
    }

    public var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            severityIcon
            FDSLabel(text)
                .font(AppTypography.bodySm)
                .foregroundStyle(AppColors.Text.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(severityBackground, in: RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .strokeBorder(severityColor.opacity(0.25), lineWidth: 1)
        )
    }

    private var severityIcon: some View {
        Image(systemName: severitySymbol)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(severityColor)
            .frame(width: 20, height: 20)
    }

    private var severitySymbol: String {
        switch severity {
        case .info: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .alert: "exclamationmark.octagon.fill"
        }
    }

    private var severityColor: Color {
        switch severity {
        case .info: AppColors.info
        case .warning: AppColors.warning
        case .alert: AppColors.danger
        }
    }

    private var severityBackground: Color {
        severityColor.opacity(0.08)
    }
}
