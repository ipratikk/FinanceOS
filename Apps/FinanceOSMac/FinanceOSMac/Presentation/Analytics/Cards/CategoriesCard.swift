import FinanceCore
import FinanceUI
import SwiftUI

struct CategoriesCard: View {
    let items: [CategorySpendSummary]

    private var topItems: [CategorySpendSummary] {
        Array(items.prefix(5))
    }

    var body: some View {
        FDSCard(cornerRadius: 16, padded: false) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    FDSLabel("Categories")
                        .font(AppTypography.headingSmall)
                        .foregroundStyle(AppColors.Text.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(AppTypography.captionLg)
                        .foregroundStyle(AppColors.Text.tertiary)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)

                VStack(spacing: 0) {
                    ForEach(Array(topItems.enumerated()), id: \.element.id) { idx, item in
                        categoryRow(item)
                        if idx < topItems.count - 1 {
                            Divider().opacity(0.12).padding(.horizontal, AppSpacing.md)
                        }
                    }
                }
                .padding(.bottom, AppSpacing.sm)
            }
        }
    }

    private func categoryRow(_ item: CategorySpendSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(CategorySymbol.color(for: item.id).opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: CategorySymbol.symbol(for: item.id))
                        .font(AppTypography.captionSm)
                        .foregroundStyle(CategorySymbol.color(for: item.id))
                }
                FDSLabel(item.displayName)
                    .font(AppTypography.bodySmMedium)
                    .foregroundStyle(AppColors.Text.primary)
                    .lineLimit(1)
                Spacer()
                FDSLabel(String(format: "%.0f%%", item.percentage))
                    .font(AppTypography.bodySmSemibold)
                    .foregroundStyle(AppColors.Text.primary)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.Text.secondary.opacity(0.08))
                        .frame(height: 3)
                    Capsule()
                        .fill(CategorySymbol.color(for: item.id))
                        .frame(width: geo.size.width * (item.percentage / 100), height: 3)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}
