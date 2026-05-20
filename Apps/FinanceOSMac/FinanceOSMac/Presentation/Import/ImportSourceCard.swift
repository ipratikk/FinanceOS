import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

struct ImportSourceCard: View {
    let source: StatementSource
    let matchedBank: Banks?
    let isSelected: Bool
    let onSelect: (StatementSource) -> Void

    private var formatLabel: String {
        source.allowedFormats
            .map { $0.rawValue.uppercased() }
            .joined(separator: " · ")
    }

    var body: some View {
        Button(action: { onSelect(source) }, label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    bankLogoView

                    VStack(alignment: .leading, spacing: 2) {
                        FDSLabel(matchedBank?.displayName ?? source.bankName)
                            .font(AppTypography.bodyMd)
                            .foregroundColor(DesignTokens.Text.primary)

                        FDSLabel(source.sourceType.rawValue)
                            .font(AppTypography.labelSmall)
                            .foregroundColor(DesignTokens.Text.tertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(AppTypography.bodySmSemibold)
                        .foregroundColor(DesignTokens.Text.secondary)
                }

                FDSLabel(formatLabel)
                    .font(AppTypography.labelSmall)
                    .foregroundColor(DesignTokens.Text.quaternary)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected
                    ? AppColors.accent.opacity(0.1)
                    : DesignTokens.Background.surfaceGlass
            )
            .cornerRadius(AppRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .strokeBorder(
                        isSelected ? AppColors.accent : DesignTokens.Border.subtle,
                        lineWidth: 1
                    )
            )
        })
        .buttonStyle(.plain)
        .contentShape(Rectangle())
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
                .fill(DesignTokens.Background.surfaceGlass)
                .frame(width: AppSpacing.xxxl, height: AppSpacing.xxxl)
                .overlay(
                    Image(systemName: "building.columns")
                        .font(AppTypography.bodyMd)
                        .foregroundColor(DesignTokens.Text.tertiary)
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
