import Foundation

public enum CardCatalogLoader {
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
                    let metadata = CardMetadata(
                        id: card.id,
                        issuer: issuer.name,
                        name: card.name,
                        cardType: card.network.lowercased(),
                        variant: card.variant,
                        binRanges: card.binRanges.map { bin in
                            CardMetadata.BINRange(start: bin.start, end: bin.end)
                        },
                        imageURL: card.image.front,
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
        let binRanges: [BINRange]
        let image: Image
        let theme: Theme
        let details: Details
        let parsingHints: ParsingHints

        struct BINRange: Decodable {
            let start: String
            let end: String
        }

        struct Image: Decodable {
            let front: String
            let thumbnail: String
            let localAssetName: String
            let aspectRatio: String
        }

        struct Theme: Decodable {
            let primaryColor: String
            let secondaryColor: String
            let textColor: String
            let accentColor: String
        }

        struct Details: Decodable {
            let annualFee: String?
            let joiningBenefit: String?
            let features: [String]
            let eligibility: String
        }

        struct ParsingHints: Decodable {
            let statementAliases: [String]
            let issuerName: String
        }
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
