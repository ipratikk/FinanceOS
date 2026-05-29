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
