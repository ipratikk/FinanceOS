import FinanceCore
import FinanceUI
import SwiftUI

struct CardSelectionView: View {
    @State private var selectedCard: CardMetadata?
    @State private var searchText: String = ""
    @State private var allCards: [CardMetadata] = CardDatabase.supportedCards()
    @State private var allIssuers: [String] = CardDatabase.issuers()
    @State private var selectedIssuer: String? = CardDatabase.issuers().first
    var onSelect: (CardMetadata) -> Void
    var onDismiss: () -> Void

    var filteredCards: [CardMetadata] {
        let cards = selectedIssuer.map { issuer in
            allCards.filter { $0.issuer == issuer }
        } ?? allCards
        return cards.filter { card in
            searchText.isEmpty || card.name.lowercased().contains(searchText.lowercased())
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                FDSLabel("Select Card", style: .headingMedium)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .headingSmall()
                        .foregroundColor(.gray)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.base)

            Divider()

            VStack(spacing: 12) {
                // Debug: Show card counts
                FDSLabel(
                    "Available: \(allCards.count) | Filtered: \(filteredCards.count) | Selected issuer: \(selectedIssuer ?? "All")",
                    style: .caption
                )
                .padding(AppSpacing.sm)

                // Issuer Filter
                HStack(spacing: 8) {
                    FDSLabel("Issuer:", style: .hint)
                    Menu {
                        Button("All", action: { selectedIssuer = nil })
                        Divider()
                        ForEach(allIssuers, id: \.self) { issuer in
                            Button(issuer) { selectedIssuer = issuer }
                        }
                    } label: {
                        HStack {
                            FDSLabel(selectedIssuer ?? "All", style: .bodyMedium)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.white)
                        .padding(AppSpacing.xs)
                        .background(AppColors.accent)
                        .cornerRadius(AppRadius.sm)
                    }
                    Spacer()
                }
                .padding(AppSpacing.md)

                // Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textTertiary)
                    TextField("Search cards...", text: $searchText)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                }
                .padding(AppSpacing.xs)
                .background(AppColors.surface2)
                .cornerRadius(AppRadius.sm)
                .padding(AppSpacing.md)
            }
            .background(AppColors.base)

            // Card List
            if filteredCards.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "creditcard.slash")
                        .font(.system(size: 32))
                        .foregroundColor(AppColors.textTertiary)
                    FDSLabel("No cards found", style: .bodyMedium)
                        .foregroundColor(AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.base)
            } else {
                List(filteredCards, id: \.id) { card in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            FDSLabel(card.name, style: .monoAmount)
                            HStack(spacing: 8) {
                                FDSLabel(card.variant.capitalized, style: .hint)
                                FDSLabel(card.cardType.uppercased(), style: .hint)
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                        Spacer()
                        Button(action: {
                            selectedCard = card
                            onSelect(card)
                        }) {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(selectedCard?.id == card.id ? AppColors.accent : AppColors
                                    .textTertiary)
                        }
                    }
                    .listRowBackground(AppColors.surface)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .background(AppColors.base)
                .scrollContentBackground(.hidden)
            }
        }
        .background(AppColors.base)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    CardSelectionView(
        onSelect: { _ in },
        onDismiss: {}
    )
}
