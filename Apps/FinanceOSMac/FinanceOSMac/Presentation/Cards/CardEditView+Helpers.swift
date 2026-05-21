import FinanceCore
import FinanceUI
import SwiftUI

struct CardCatalogWidget: View {
    let card: CardMetadata

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            CardArtworkDisplay(card: card)
            VStack(alignment: .leading, spacing: 3) {
                FDSLabel(card.name)
                    .font(AppTypography.bodyMd)
                    .foregroundStyle(AppColors.Text.primary)
                    .lineLimit(1)
                FDSLabel(card.cardType.displayName.uppercased())
                    .font(AppTypography.captionSm)
                    .foregroundStyle(AppColors.Text.secondary)
                    .tracking(0.5)
            }
            Spacer()
        }
        .padding(AppSpacing.compact)
        .background(AppColors.accentLight)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .strokeBorder(AppColors.accent.opacity(0.2), lineWidth: 0.5)
        )
    }
}

struct CardArtworkDisplay: View {
    let card: CardMetadata

    var body: some View {
        Group {
            if let urlString = card.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if case let .success(image) = phase {
                        image.resizable().scaledToFit()
                    } else {
                        cardPlaceholder
                    }
                }
            } else {
                cardPlaceholder
            }
        }
        .frame(width: 56, height: 36)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .strokeBorder(AppColors.textPrimary.opacity(0.12), lineWidth: 0.5)
        )
    }

    private var cardPlaceholder: some View {
        RoundedRectangle(cornerRadius: AppRadius.sm)
            .fill(.ultraThinMaterial)
            .overlay {
                Image(systemName: "creditcard.fill")
                    .font(AppTypography.bodyMdLight)
                    .foregroundStyle(.tertiary)
            }
    }
}

struct CardDeleteConfirmationAlert: View {
    let isCard: Bool
    let card: Ledger
    let context: CardEditContext
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(AppTypography.netHeroAmount)
                    .foregroundStyle(AppColors.danger)

                FDSLabel("Delete \(isCard ? "Card" : "Account")?")
                    .font(AppTypography.headingLg)
                    .foregroundStyle(AppColors.Text.primary)

                FDSLabel(
                    "This will permanently delete this \(isCard ? "card" : "account") and all associated transactions."
                )
                .font(AppTypography.bodyMd)
                .foregroundStyle(AppColors.Text.secondary)
            }

            HStack(spacing: AppSpacing.compact) {
                FDSLiquidButton("Cancel", variant: .ghost) { isPresented = false }
                Spacer()
                FDSLiquidButton("Delete", variant: .danger) {
                    Task {
                        await context.deleteCard(id: card.id)
                        if context.deleteError == nil { dismiss() }
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
    }
}
