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
        let cards = selectedIssuer.map { issuer in
            allCards.filter { $0.issuer == issuer }
        } ?? allCards
        return cards.filter { card in
            searchText.isEmpty || card.name.lowercased().contains(searchText.lowercased())
        }
    }

    private func networkLogoURL(for type: String) -> URL? {
        let urls: [String: String] = [
            "visa": "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Visa_Inc._logo.svg/1200px-Visa_Inc._logo.svg.png",
            "mastercard": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Mastercard-logo.svg/1024px-Mastercard-logo.svg.png",
            "amex": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/39/American_Express_logo.svg/1200px-American_Express_logo.svg.png",
            "rupay": "https://upload.wikimedia.org/wikipedia/en/6/6d/RuPay_logo.svg",
            "discover": "https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Discover_Card_logo.svg/1024px-Discover_Card_logo.svg.png",
            "diners": "https://upload.wikimedia.org/wikipedia/commons/thumb/5/58/Diners_Club_logo.svg/1024px-Diners_Club_logo.svg.png"
        ]
        return urls[type.lowercased()].flatMap { URL(string: $0) }
    }

    private func bankLogo(for issuer: String) -> NSImage? {
        let assetNames: [String: String] = [
            "HDFC Bank": "hdfc-symbol",
            "ICICI Bank": "icici-symbol"
        ]

        if let assetName = assetNames[issuer],
           let nsImage = NSImage(named: assetName)
        {
            return nsImage
        }

        return nil
    }

    private func networkColor(for type: String) -> Color {
        switch type.lowercased() {
        case "visa":
            return Color(red: 0.13, green: 0.20, blue: 0.79)
        case "mastercard":
            return Color(red: 0.92, green: 0, blue: 0.1)
        case "amex":
            return Color(red: 0.01, green: 0.33, blue: 0.76)
        case "rupay":
            return Color(red: 0.11, green: 0.15, blue: 0.32)
        case "discover":
            return Color(red: 1, green: 0.6, blue: 0)
        case "diners":
            return Color(red: 0, green: 0.51, blue: 0.73)
        default:
            return AppColors.textSecondary
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
            List(filteredCards, id: \.id) { card in
                HStack(spacing: 12) {
                    // Card Image + Network Logo
                    ZStack(alignment: .bottomTrailing) {
                        AsyncImage(url: URL(string: card.imageURL ?? "")) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppColors.surface2)
                                    .frame(width: 100, height: 65)
                            case let .success(image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 65)
                                    .cornerRadius(8)
                            case .failure:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppColors.surface2)
                                    .frame(width: 100, height: 65)
                                    .overlay(
                                        Image(systemName: "creditcard")
                                            .foregroundColor(AppColors.textTertiary)
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }

                        // Network Logo Badge
                        SVGImageView(networkLogoURL(for: card.cardType), width: 28, height: 18)
                            .padding(4)
                            .background(Color.white)
                            .cornerRadius(4)
                    }
                    .frame(width: 100, height: 65)

                    // Card Info
                    VStack(alignment: .leading, spacing: 6) {
                        FDSLabel(card.name, style: .monoAmount)

                        HStack(spacing: 8) {
                            // Bank Logo
                            if let logo = bankLogo(for: card.issuer) {
                                Image(nsImage: logo)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 16)
                            }

                            Spacer()
                            FDSLabel(card.cardType.uppercased(), style: .caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(networkColor(for: card.cardType).opacity(0.1))
                                .foregroundColor(networkColor(for: card.cardType))
                                .cornerRadius(3)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Select Button
                    Button(action: {
                        selectedCard = card
                        onSelect(card)
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(selectedCard?.id == card.id ? AppColors.accent : AppColors.textTertiary)
                    }
                }
                .padding(AppSpacing.sm)
                .listRowBackground(AppColors.surface)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .background(AppColors.base)
            .scrollContentBackground(.hidden)
            .frame(maxHeight: .infinity)
        }
        .background(AppColors.base)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            allCards = CardDatabase.supportedCards()
            allIssuers = CardDatabase.issuers()
            if selectedIssuer == nil, !allIssuers.isEmpty {
                selectedIssuer = allIssuers.first
            }
        }
    }
}

#Preview {
    CardSelectionView(
        onSelect: { _ in },
        onDismiss: {}
    )
}
