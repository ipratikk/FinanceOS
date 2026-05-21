import FinanceCore
import SwiftUI

public enum FDSPickerVariant {
    case logoOnly
    case symbolText
    case textOnly
}

struct FDSPickerRow: View {
    let option: FDSPickerOption
    let variant: FDSPickerVariant
    let isSelected: Bool

    var body: some View {
        switch variant {
        case .logoOnly:
            logoOnlyVariant
        case .symbolText:
            symbolTextVariant
        case .textOnly:
            textOnlyVariant
        }
    }

    private var symbolTextVariant: some View {
        HStack(spacing: AppSpacing.compact) {
            FDSImage(
                imageName: option.imageName,
                fallbackSymbol: option.symbol,
                height: 28,
                width: 28
            )

            VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                FDSLabel(option.title)
                    .font(AppTypography.bodyMd)
                    .foregroundStyle(isSelected ? AppColors.accent : AppColors.Text.primary)

                if let subtitle = option.subtitle {
                    FDSLabel(subtitle)
                        .font(AppTypography.captionSm)
                        .foregroundStyle(AppColors.Text.secondary)
                }

                if let badge = option.badge {
                    FBadge(badge, color: .blue, icon: nil)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(AppTypography.bodyMdSemibold)
                    .foregroundStyle(AppColors.accent)
            }
        }
        .padding(.vertical, AppSpacing.compact)
        .padding(.horizontal, AppSpacing.md)
        .background(isSelected ? AppColors.accent.opacity(0.08) : .clear)
    }

    private var logoOnlyVariant: some View {
        HStack(spacing: AppSpacing.sm) {
            FDSImage(
                imageName: option.imageName,
                fallbackSymbol: option.symbol,
                height: 36,
                width: 36
            )

            FDSLabel(option.title)
                .font(AppTypography.captionSm)
                .foregroundStyle(AppColors.Text.primary)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(AppTypography.captionLgSemibold)
                    .foregroundStyle(AppColors.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(isSelected ? AppColors.accent.opacity(0.08) : .clear)
        .clipped()
    }

    private var textOnlyVariant: some View {
        HStack(spacing: AppSpacing.compact) {
            VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                FDSLabel(option.title)
                    .font(AppTypography.bodyMd)
                    .foregroundStyle(isSelected ? AppColors.accent : AppColors.Text.primary)

                if let subtitle = option.subtitle {
                    FDSLabel(subtitle)
                        .font(AppTypography.captionSm)
                        .foregroundStyle(AppColors.Text.secondary)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .font(AppTypography.captionLgSemibold)
                    .foregroundStyle(AppColors.accent)
            }
        }
        .padding(.vertical, AppSpacing.compact)
        .padding(.horizontal, AppSpacing.md)
        .background(isSelected ? AppColors.accent.opacity(0.08) : .clear)
    }
}
