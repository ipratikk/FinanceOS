import FinanceCore
import FinanceUI
import SwiftUI

struct CardSelectionView: View {
    @State private var selectedCard: CardMetadata?
    @State private var searchText: String = ""
    @State private var allCards: [CardMetadata] = []
    @State private var allIssuers: [String] = []
    @State private var selectedIssuer: String?
    var onSelect: (CardMetadata) -> Void
    var onDismiss: () -> Void

    var filteredCards: [CardMetadata] {
        let base = selectedIssuer.map { issuer in allCards.filter { $0.issuer == issuer } } ?? allCards
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.3)
            searchBar
            issuerChipRow
            Divider().opacity(0.3)
            cardList
        }
        .background(AppColors.base)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            allCards = CardDatabase.supportedCards()
            allIssuers = CardDatabase.issuers()
        }
    }

    private var header: some View {
        HStack(spacing: AppSpacing.compact) {
            Image(systemName: "creditcard.fill")
                .font(AppTypography.headlineSm)
                .foregroundStyle(AppColors.accent)
                .symbolRenderingMode(.hierarchical)
            FDSLabel("Select Card", style: .bodyMedium)
            Spacer()
            AccessibleIconButton.close(action: onDismiss)
        }
        .padding(AppSpacing.md)
    }

    private var searchBar: some View {
        HStack(spacing: AppSpacing.compact) {
            Image(systemName: "magnifyingglass")
                .font(AppTypography.captionLgSemibold)
                .foregroundStyle(.tertiary)
            FDSTextInput("Search cards", text: $searchText, style: .bodyMedium)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(AppTypography.captionLg)
                        .foregroundStyle(.tertiary)
                })
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.compact)
        .padding(.vertical, 6)
        .background { Capsule(style: .continuous).fill(.ultraThinMaterial) }
        .overlay { Capsule(style: .continuous).strokeBorder(AppColors.textPrimary.opacity(0.06), lineWidth: 0.5) }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.compact)
    }

    private var issuerChipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.compact) {
                issuerChip("All", selected: selectedIssuer == nil) { selectedIssuer = nil }
                ForEach(allIssuers, id: \.self) { issuer in
                    issuerChip(issuer, selected: selectedIssuer == issuer) { selectedIssuer = issuer }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.compact)
        }
    }

    private func issuerChip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            FDSLabel(label)
                .font(selected ? AppTypography.captionLgSemibold : AppTypography.captionLg)
                .foregroundStyle(selected ? AppColors.accent : AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 5)
                .background {
                    Capsule(style: .continuous)
                        .fill(selected ? AppColors.accent.opacity(0.15) : AppColors.clear)
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(
                                    selected ? AppColors.accent.opacity(0.5) : AppColors.textSecondary.opacity(0.2),
                                    lineWidth: 0.5
                                )
                        )
                }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: selected)
    }

    private var cardList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: AppSpacing.compact) {
                ForEach(filteredCards) { card in
                    cardRow(card)
                }
            }
            .padding(AppSpacing.md)
        }
    }

    private func cardRow(_ card: CardMetadata) -> some View {
        let isSelected = selectedCard?.id == card.id
        return Button {
            selectedCard = card
            onSelect(card)
        } label: {
            HStack(spacing: AppSpacing.md) {
                cardArtwork(for: card)

                VStack(alignment: .leading, spacing: 4) {
                    FDSLabel(card.name)
                        .font(AppTypography.bodySmMedium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        FDSLabel(card.issuer)
                            .font(AppTypography.captionSm)
                            .foregroundStyle(.secondary)
                        FDSLabel("·")
                            .foregroundStyle(.quaternary)
                        networkBadge(for: card)
                    }
                }

                Spacer(minLength: AppSpacing.compact)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(AppTypography.headingMdRegular)
                    .foregroundStyle(isSelected ? AppColors.accent : AppColors.textSecondary.opacity(0.4))
            }
            .padding(AppSpacing.md)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(isSelected ? AppColors.accent.opacity(0.08) : AppColors.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .strokeBorder(
                                isSelected ? AppColors.accent.opacity(0.35) : AppColors.textPrimary.opacity(0.05),
                                lineWidth: isSelected ? 1 : 0.5
                            )
                    )
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
    }

    private func cardArtwork(for card: CardMetadata) -> some View {
        Group {
            if let urlString = card.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image.resizable().scaledToFit()
                    default:
                        artworkPlaceholder
                    }
                }
            } else {
                artworkPlaceholder
            }
        }
        .frame(width: 88, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(AppColors.textPrimary.opacity(0.12), lineWidth: 0.5)
        }
    }

    private var artworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                Image(systemName: "creditcard.fill")
                    .font(AppTypography.headingLgLight)
                    .foregroundStyle(.tertiary)
            }
    }

    private func networkBadge(for card: CardMetadata) -> some View {
        FDSLabel(card.cardType.displayName.uppercased())
            .font(AppTypography.iconSm)
            .tracking(0.4)
            .foregroundStyle(networkColor(for: card.cardType))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background {
                Capsule(style: .continuous)
                    .fill(networkColor(for: card.cardType).opacity(0.12))
            }
    }

    private func networkColor(for network: CardNetwork) -> Color {
        switch network {
        case .visa: Color(red: 0.13, green: 0.20, blue: 0.79)
        case .mastercard: Color(red: 0.92, green: 0, blue: 0.1)
        case .amex: Color(red: 0.01, green: 0.33, blue: 0.76)
        case .rupay: Color(red: 0.11, green: 0.15, blue: 0.32)
        case .discover: Color(red: 1, green: 0.6, blue: 0)
        case .diners: Color(red: 0, green: 0.51, blue: 0.73)
        case .other: AppColors.textSecondary
        }
    }
}

#Preview {
    CardSelectionView(onSelect: { _ in }, onDismiss: {})
}
