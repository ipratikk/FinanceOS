import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

struct ImportSourceCard: View {
    let source: StatementSource
    let matchedBank: Banks?
    let isSelected: Bool
    let onSelect: (StatementSource) -> Void

    var body: some View {
        Button(action: { onSelect(source) }, label: {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                HStack(spacing: 12) {
                    bankLogoView

                    VStack(alignment: .leading, spacing: AppSpacing.tight) {
                        FDSLabel(matchedBank?.displayName ?? source.bankName)
                            .font(AppTypography.headingSmall)
                            .foregroundColor(AppColors.Text.primary)

                        FDSLabel(source.sourceType.rawValue)
                            .font(AppTypography.labelSmall)
                            .foregroundColor(AppColors.Text.tertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(AppTypography.bodySmSemibold)
                        .foregroundColor(AppColors.Text.secondary)
                }

                formatBadges
            }
            .padding(AppSpacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected
                    ? AppColors.accent.opacity(0.1)
                    : AppColors.Glass.surface
            )
            .cornerRadius(AppRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .strokeBorder(
                        isSelected ? AppColors.accent : AppColors.Border.subtle,
                        lineWidth: 1
                    )
            )
        })
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private var formatBadges: some View {
        let labels = source.allowedFormats.map { $0.rawValue.uppercased() }
        return HStack(spacing: 6) {
            ForEach(labels, id: \.self) { label in
                FDSChip(label, isActive: false) {}
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var bankLogoView: some View {
        if let bank = matchedBank {
            Image(bank.symbolAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: AppSpacing.xxxl, height: AppSpacing.xxxl)
        } else {
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .fill(AppColors.Glass.surface)
                .frame(width: AppSpacing.xxxl, height: AppSpacing.xxxl)
                .overlay(
                    Image(systemName: "building.columns")
                        .font(AppTypography.bodyMd)
                        .foregroundColor(AppColors.Text.tertiary)
                )
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ImportSourceCard(
            source: .hdfcBank,
            matchedBank: .hdfc,
            isSelected: false,
            onSelect: { _ in }
        )
        ImportSourceCard(
            source: .hdfcCard,
            matchedBank: .hdfc,
            isSelected: true,
            onSelect: { _ in }
        )
        ImportSourceCard(
            source: .amex,
            matchedBank: .amex,
            isSelected: false,
            onSelect: { _ in }
        )
    }
    .padding()
    .background(AppColors.base)
}
