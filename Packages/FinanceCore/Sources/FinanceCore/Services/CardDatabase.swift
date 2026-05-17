import Foundation

public enum CardDatabase {
    private static let defaultCards: [CardMetadata] = [
        // HDFC Cards
        CardMetadata(
            id: "hdfc-credit",
            issuer: "HDFC",
            name: "HDFC Bank Credit Card",
            cardType: "mastercard",
            variant: "credit",
            binRanges: [
                .init(start: "510029", end: "510029"),
                .init(start: "512345", end: "512345")
            ],
            details: .init(
                description: "HDFC Bank standard credit card",
                features: ["Cashback", "Rewards points"],
                annualFee: "Free",
                eligibility: "Age 21-70"
            ),
            isSupported: true
        ),
        CardMetadata(
            id: "hdfc-debit",
            issuer: "HDFC",
            name: "HDFC Bank Debit Card",
            cardType: "mastercard",
            variant: "debit",
            binRanges: [
                .init(start: "553200", end: "553299")
            ],
            details: .init(
                description: "HDFC Bank primary debit card",
                features: ["ATM access", "Online transactions"],
                annualFee: nil
            ),
            isSupported: true
        ),
        // ICICI Cards
        CardMetadata(
            id: "icici-credit",
            issuer: "ICICI",
            name: "ICICI Bank Credit Card",
            cardType: "visa",
            variant: "credit",
            binRanges: [
                .init(start: "401200", end: "401299"),
                .init(start: "456789", end: "456789")
            ],
            details: .init(
                description: "ICICI Bank credit card",
                features: ["Rewards", "Shopping benefits"],
                annualFee: "Free",
                eligibility: "Age 21+"
            ),
            isSupported: true
        ),
        CardMetadata(
            id: "icici-debit",
            issuer: "ICICI",
            name: "ICICI Bank Debit Card",
            cardType: "visa",
            variant: "debit",
            binRanges: [
                .init(start: "421056", end: "421065")
            ],
            details: .init(
                description: "ICICI Bank debit card",
                features: ["ATM access", "Online shopping"],
                annualFee: nil
            ),
            isSupported: true
        ),
        // American Express
        CardMetadata(
            id: "amex-green",
            issuer: "American Express",
            name: "American Express Green Card",
            cardType: "amex",
            variant: "credit",
            binRanges: [
                .init(start: "374282", end: "374282")
            ],
            details: .init(
                description: "AmEx basic credit card",
                features: ["Travel benefits", "Purchase protection"],
                annualFee: "$95",
                eligibility: "Age 18+"
            ),
            isSupported: true
        ),
        CardMetadata(
            id: "amex-gold",
            issuer: "American Express",
            name: "American Express Gold Card",
            cardType: "amex",
            variant: "credit",
            binRanges: [
                .init(start: "378282", end: "378282")
            ],
            details: .init(
                description: "AmEx premium credit card",
                features: ["Concierge", "Premium travel", "Dining credits"],
                annualFee: "$295",
                eligibility: "Annual income $25k+"
            ),
            isSupported: true
        ),
        // Scapia (assuming Rupay is primary)
        CardMetadata(
            id: "scapia-credit",
            issuer: "Scapia",
            name: "Scapia Credit Card",
            cardType: "rupay",
            variant: "credit",
            binRanges: [
                .init(start: "607844", end: "607844")
            ],
            details: .init(
                description: "Scapia Rupay credit card",
                features: ["Cashback", "Rewards"],
                annualFee: "Free",
                eligibility: "Age 21+"
            ),
            isSupported: true
        )
    ]

    public static func allCards() -> [CardMetadata] {
        defaultCards
    }

    public static func cardsByIssuer(_ issuer: String) -> [CardMetadata] {
        defaultCards.filter { $0.issuer.lowercased() == issuer.lowercased() }
    }

    public static func findCard(by bin: String) -> CardMetadata? {
        defaultCards.first { $0.matches(bin) }
    }

    public static func issuers() -> [String] {
        Array(Set(defaultCards.map(\.issuer))).sorted()
    }

    public static func supportedCards() -> [CardMetadata] {
        defaultCards.filter(\.isSupported)
    }
}
