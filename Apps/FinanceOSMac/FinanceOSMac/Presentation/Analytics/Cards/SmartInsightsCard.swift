import FinanceCore
import FinanceIntelligence
import FinanceUI
import SwiftUI

struct SmartInsightsCard: View {
    let insights: [TransactionInsight]

    private var topInsight: TransactionInsight? {
        insights.first { $0.kind == .spendingSpike || $0.kind == .categoryTrend }
            ?? insights.first
    }

    private var subscriptions: [TransactionInsight] {
        insights.filter { $0.kind == .subscriptionDetected }.prefix(2).map(\.self)
    }

    var body: some View {
        FDSCard(cornerRadius: 16, padded: false) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                headerRow
                if let insight = topInsight {
                    insightText(insight)
                } else {
                    emptyInsight
                }
                if !subscriptions.isEmpty {
                    subscriptionSection
                }
                Spacer(minLength: 0)
                auditButton
            }
            .padding(AppSpacing.md)
        }
    }

    private var headerRow: some View {
        HStack(spacing: AppSpacing.compact) {
            Image(systemName: "sparkles")
                .font(AppTypography.captionLgSemibold)
                .foregroundStyle(AppColors.accentGreen)
            FDSLabel("Smart Insights")
                .font(AppTypography.headingSmall)
                .foregroundStyle(AppColors.Text.primary)
        }
    }

    private func insightText(_ insight: TransactionInsight) -> some View {
        FDSLabel(insight.explanation)
            .font(AppTypography.bodySm)
            .foregroundStyle(AppColors.Text.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var emptyInsight: some View {
        FDSLabel("Import more statements to unlock spending insights.")
            .font(AppTypography.bodySm)
            .foregroundStyle(AppColors.Text.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.compact) {
            FDSLabel("SUBSCRIPTIONS DETECTED")
                .font(AppTypography.captionSmSemibold)
                .tracking(0.8)
                .foregroundStyle(AppColors.Text.tertiary)

            ForEach(subscriptions) { sub in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        FDSLabel(sub.title)
                            .font(AppTypography.bodySmMedium)
                            .foregroundStyle(AppColors.Text.primary)
                            .lineLimit(1)
                        FDSLabel(sub.kind == .subscriptionDetected ? "Auto-categorized" : "Detected pattern")
                            .font(AppTypography.captionSm)
                            .foregroundStyle(AppColors.Text.tertiary)
                    }
                    Spacer()
                    FDSLabel(sub.kind == .subscriptionDetected ? "Recurring" : "Spike")
                        .font(AppTypography.captionSmSemibold)
                        .foregroundStyle(AppColors.accentOrange)
                        .padding(.horizontal, AppSpacing.compact)
                        .padding(.vertical, 2)
                        .background(AppColors.accentOrange.opacity(0.12))
                        .cornerRadius(4)
                }
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.Text.secondary.opacity(0.05))
        .cornerRadius(10)
    }

    private var auditButton: some View {
        Button(action: {}, label: {
            FDSLabel("View Detailed Audit")
                .font(AppTypography.bodySmSemibold)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.sm)
                .background(AppColors.accentGreen)
                .cornerRadius(10)
        })
        .buttonStyle(.plain)
        .opacity(insights.isEmpty ? 0.4 : 1)
        .disabled(insights.isEmpty)
    }
}
