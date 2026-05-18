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
                FDSLabel(
                    option.title,
                    style: .bodyMedium,
                    color: isSelected ? .accent : .primary
                )

                if let subtitle = option.subtitle {
                    FDSLabel(subtitle, style: .caption, color: .secondary)
                }

                if let badge = option.badge {
                    FBadge(badge, color: .blue, icon: nil)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
            }
        }
        .padding(.vertical, AppSpacing.compact)
        .padding(.horizontal, AppSpacing.md)
        .background(isSelected ? AppColors.accent.opacity(0.08) : .clear)
        .clipped()
    }

    private var logoOnlyVariant: some View {
        VStack(spacing: AppSpacing.sm) {
            FDSImage(
                imageName: option.imageName,
                fallbackSymbol: option.symbol,
                height: 36,
                width: 36
            )

            FDSLabel(option.title, style: .caption)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
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
                FDSLabel(
                    option.title,
                    style: .bodyMedium,
                    color: isSelected ? .accent : .primary
                )

                if let subtitle = option.subtitle {
                    FDSLabel(subtitle, style: .caption, color: .secondary)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
            }
        }
        .padding(.vertical, AppSpacing.compact)
        .padding(.horizontal, AppSpacing.md)
        .background(isSelected ? AppColors.accent.opacity(0.08) : .clear)
        .clipped()
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        FDSPickerRow(
            option: FDSPickerOption(
                id: "hdfc",
                title: "HDFC Bank",
                subtitle: "•••• 6521",
                symbol: "building.columns.fill"
            ),
            variant: .symbolText,
            isSelected: true
        )

        Divider()

        FDSPickerRow(
            option: FDSPickerOption(
                id: "visa",
                title: "Visa",
                symbol: "creditcard.fill"
            ),
            variant: .logoOnly,
            isSelected: false
        )

        Divider()

        FDSPickerRow(
            option: FDSPickerOption(
                id: "checking",
                title: "Checking",
                subtitle: "Account Type"
            ),
            variant: .textOnly,
            isSelected: false
        )
    }
    .padding(AppSpacing.md)
    .background(AppColors.base)
}
