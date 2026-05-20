import Foundation

public enum CardCatalogLoader {
    public enum LogoSize {
        case small
        case large
    }

    public static func bankLogoURL(
        for issuer: String,
        size: LogoSize = .large
    ) -> URL? {
        let logos: [String: (small: String, large: String)] = [
            "HDFC Bank": (small: "bank-logos/hdfc-small", large: "bank-logos/hdfc"),
            "ICICI Bank": (small: "bank-logos/icici-small", large: "bank-logos/icici")
        ]

        let assetName = size == .small ? logos[issuer]?.small : logos[issuer]?.large

        if let assetName,
           let assetURL = Bundle.module.url(forResource: assetName, withExtension: nil) {
            return assetURL
        }

        return nil
    }

    private static func resolveImageURL(_ path: String) -> String {
        // If already a URL, return as-is
        if path.hasPrefix("http") {
            return path
        }

        // Local asset - resolve from bundle
        if path.hasPrefix("bank-logos/") {
            if let assetURL = Bundle.module.url(forResource: path, withExtension: nil) {
                return assetURL.absoluteString
            }
        }

        return path
    }

    public static func loadCardMetadata() -> [CardMetadata] {
        guard let url = Bundle.module.url(forResource: "cards_catalog", withExtension: "json") else {
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let catalog = try decoder.decode(CardCatalog.self, from: data)

            var cards: [CardMetadata] = []
            for issuer in catalog.issuers {
                for card in issuer.cards {
                    let imageURL = resolveImageURL(card.image.front)

                    let metadata = CardMetadata(
                        id: card.id,
                        issuer: issuer.name,
                        name: card.name,
                        cardType: CardNetwork(rawValue: card.network.lowercased()) ?? .other,
                        variant: card.variant,
                        binRanges: card.binRanges.map { bin in
                            CardMetadata.BINRange(start: bin.start, end: bin.end)
                        },
                        imageURL: imageURL,
                        details: CardMetadata.CardDetails(
                            description: card.details.joiningBenefit ?? card.name,
                            features: card.details.features,
                            annualFee: card.details.annualFee,
                            eligibility: card.details.eligibility
                        ),
                        isSupported: card.active
                    )
                    cards.append(metadata)
                }
            }
            return cards
        } catch {
            print("Failed to load card catalog: \(error)")
            return []
        }
    }
}

// MARK: - Catalog Structures

private struct CardBINRange: Decodable {
    let start: String
    let end: String
}

private struct CardImage: Decodable {
    let front: String
    let thumbnail: String
    let localAssetName: String
    let aspectRatio: String
}

private struct CardTheme: Decodable {
    let primaryColor: String
    let secondaryColor: String
    let textColor: String
    let accentColor: String
}

private struct CardDetails: Decodable {
    let annualFee: String?
    let joiningBenefit: String?
    let features: [String]
    let eligibility: String
}

private struct CardParsingHints: Decodable {
    let statementAliases: [String]
    let issuerName: String
}

private struct CardCatalog: Decodable {
    struct Issuer: Decodable {
        let id: String
        let name: String
        let country: String
        let website: String
        let brandColor: String
        let logoUrl: String
        let cards: [Card]
    }

    struct Card: Decodable {
        let id: String
        let name: String
        let type: String
        let network: String
        let variant: String
        let active: Bool
        let premiumTier: Bool
        let aliases: [String]
        let binRanges: [CardBINRange]
        let image: CardImage
        let theme: CardTheme
        let details: CardDetails
        let parsingHints: CardParsingHints
    }

    struct Network: Decodable {
        let id: String
        let name: String
        let color: String
        let website: String
    }

    struct Metadata: Decodable {
        let cardCount: Int
        let issuerCount: Int
        let networkCount: Int
        let lastUpdated: String
    }

    let version: Int
    let generatedAt: String
    let issuers: [Issuer]
    let networks: [Network]
    let metadata: Metadata
}
