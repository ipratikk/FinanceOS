import Foundation

public enum CardDatabase {
    private static let defaultCards: [CardMetadata] = CardCatalogLoader.loadCardMetadata().isEmpty ?
        fallbackCards : CardCatalogLoader.loadCardMetadata()

    private static let fallbackCards: [CardMetadata] = [
        // HDFC Cards
        CardMetadata(
            id: "hdfc-credit-classic",
            issuer: "HDFC",
            name: "HDFC Bank Credit Card",
            cardType: "mastercard",
            variant: "credit",
            binRanges: [
                .init(start: "510029", end: "510029"),
                .init(start: "512345", end: "512345"),
                .init(start: "553712", end: "553712")
            ],
            imageURL: "https://www.hdfcbank.com/images/cc-classic.png",
            details: .init(
                description: "HDFC Bank Credit Card - Standard personal credit card with flexible payment options",
                features: [
                    "Cashback on retail purchases",
                    "Rewards points",
                    "EMI conversion",
                    "Credit limit up to 5 lakhs",
                    "Fuel surcharge waiver"
                ],
                annualFee: "Free for first year, Rs. 500 thereafter (waived if spends exceed Rs. 2 lakhs)",
                eligibility: "Age 21-65, Min annual income Rs. 1.5 lakh"
            ),
            isSupported: true
        ),
        CardMetadata(
            id: "hdfc-credit-premium",
            issuer: "HDFC",
            name: "HDFC Bank Regalia Credit Card",
            cardType: "mastercard",
            variant: "credit",
            binRanges: [
                .init(start: "512456", end: "512456"),
                .init(start: "553800", end: "553899")
            ],
            imageURL: "https://www.hdfcbank.com/images/cc-regalia.png",
            details: .init(
                description: "Premium credit card with lifestyle benefits and travel perks",
                features: [
                    "Lounge access",
                    "Travel insurance",
                    "Concierge services",
                    "5% cashback on dining",
                    "Movie tickets discount"
                ],
                annualFee: "Rs. 2,500 (waived on spends of Rs. 1 lakh)",
                eligibility: "Age 23-65, Min annual income Rs. 3 lakh"
            ),
            isSupported: true
        ),
        CardMetadata(
            id: "hdfc-debit-classic",
            issuer: "HDFC",
            name: "HDFC Bank Debit Card",
            cardType: "mastercard",
            variant: "debit",
            binRanges: [
                .init(start: "553200", end: "553299"),
                .init(start: "676290", end: "676290")
            ],
            imageURL: "https://www.hdfcbank.com/images/dc-classic.png",
            details: .init(
                description: "Primary debit card with ATM access and online transaction capability",
                features: [
                    "ATM withdrawals",
                    "Online shopping",
                    "International usage",
                    "Zero balance",
                    "Contactless payments"
                ],
                annualFee: nil,
                eligibility: "All account holders"
            ),
            isSupported: true
        ),

        // ICICI Cards
        CardMetadata(
            id: "icici-credit-instant",
            issuer: "ICICI",
            name: "ICICI Bank Instant Access Credit Card",
            cardType: "visa",
            variant: "credit",
            binRanges: [
                .init(start: "401200", end: "401299"),
                .init(start: "456789", end: "456789"),
                .init(start: "501061", end: "501061")
            ],
            imageURL: "https://www.icicibank.com/images/cc-instant.png",
            details: .init(
                description: "Instant approval credit card with no annual fees",
                features: ["Instant approval", "Cashback", "Rewards points", "EMI option", "Insurance coverage"],
                annualFee: "Free",
                eligibility: "Age 21+, Min annual income Rs. 1.5 lakh"
            ),
            isSupported: true
        ),
        CardMetadata(
            id: "icici-credit-coral",
            issuer: "ICICI",
            name: "ICICI Bank Coral Credit Card",
            cardType: "visa",
            variant: "credit",
            binRanges: [
                .init(start: "401300", end: "401399"),
                .init(start: "530930", end: "530930")
            ],
            imageURL: "https://www.icicibank.com/images/cc-coral.png",
            details: .init(
                description: "Premium credit card with lifestyle and shopping benefits",
                features: [
                    "10% cashback on food & movies",
                    "5% cashback on shopping",
                    "Lounge access",
                    "Travel benefits",
                    "Shopping vouchers"
                ],
                annualFee: "Rs. 3,000 (waived on spends of Rs. 1 lakh)",
                eligibility: "Age 23+, Min annual income Rs. 5 lakh"
            ),
            isSupported: true
        ),
        CardMetadata(
            id: "icici-debit-classic",
            issuer: "ICICI",
            name: "ICICI Bank Debit Card",
            cardType: "visa",
            variant: "debit",
            binRanges: [
                .init(start: "421056", end: "421065"),
                .init(start: "676311", end: "676311")
            ],
            imageURL: "https://www.icicibank.com/images/dc-classic.png",
            details: .init(
                description: "Standard debit card with global access",
                features: [
                    "ATM access worldwide",
                    "Online shopping",
                    "Contactless payments",
                    "Insurance",
                    "Mobile payments"
                ],
                annualFee: nil,
                eligibility: "All account holders"
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
                .init(start: "374282", end: "374282"),
                .init(start: "371449", end: "371449")
            ],
            imageURL: "https://www.americanexpress.com/images/amex-green.png",
            details: .init(
                description: "Entry-level Amex card with travel and shopping benefits",
                features: [
                    "Travel insurance",
                    "Purchase protection",
                    "Extended warranty",
                    "Membership rewards",
                    "Emergency assistance"
                ],
                annualFee: "$95 USD (approx Rs. 7,900)",
                eligibility: "Age 18+, Good credit score"
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
                .init(start: "378282", end: "378282"),
                .init(start: "372449", end: "372449")
            ],
            imageURL: "https://www.americanexpress.com/images/amex-gold.png",
            details: .init(
                description: "Premium Amex card with exclusive benefits and concierge services",
                features: [
                    "24/7 Concierge",
                    "Premium travel insurance",
                    "Dining credits",
                    "Airport lounge access",
                    "Upgrade vouchers"
                ],
                annualFee: "$295 USD (approx Rs. 24,500)",
                eligibility: "Annual income $25k+, Excellent credit score"
            ),
            isSupported: true
        ),
        CardMetadata(
            id: "amex-platinum",
            issuer: "American Express",
            name: "American Express Platinum Card",
            cardType: "amex",
            variant: "credit",
            binRanges: [
                .init(start: "373953", end: "373953"),
                .init(start: "370040", end: "370040")
            ],
            imageURL: "https://www.americanexpress.com/images/amex-platinum.png",
            details: .init(
                description: "Ultra-premium Amex card with exclusive privileges",
                features: [
                    "Dedicated concierge",
                    "Fine dining access",
                    "Hotel upgrades",
                    "Travel insurance premium",
                    "Personal shoppers"
                ],
                annualFee: "$695 USD (approx Rs. 57,700)",
                eligibility: "High net worth individuals, Annual income $100k+"
            ),
            isSupported: true
        ),

        // Scapia
        CardMetadata(
            id: "scapia-credit-personal",
            issuer: "Scapia",
            name: "Scapia Personal Credit Card",
            cardType: "rupay",
            variant: "credit",
            binRanges: [
                .init(start: "607844", end: "607844"),
                .init(start: "639342", end: "639342")
            ],
            imageURL: "https://www.scapia.com/images/cc-personal.png",
            details: .init(
                description: "RuPay credit card with cashback and rewards",
                features: [
                    "Cashback on all purchases",
                    "Rewards program",
                    "Online shopping discount",
                    "Bill payment options",
                    "Easy approval"
                ],
                annualFee: "Free",
                eligibility: "Age 21+, Min annual income Rs. 1 lakh"
            ),
            isSupported: true
        ),
        CardMetadata(
            id: "scapia-credit-premium",
            issuer: "Scapia",
            name: "Scapia Premium Credit Card",
            cardType: "rupay",
            variant: "credit",
            binRanges: [
                .init(start: "607845", end: "607845"),
                .init(start: "639343", end: "639343")
            ],
            imageURL: "https://www.scapia.com/images/cc-premium.png",
            details: .init(
                description: "Premium RuPay card with enhanced benefits",
                features: [
                    "5% cashback on dining",
                    "3% on travel",
                    "Lounge access",
                    "Insurance coverage",
                    "Reward multipliers"
                ],
                annualFee: "Rs. 499 (waived on spends of Rs. 50,000)",
                eligibility: "Age 23+, Min annual income Rs. 3 lakh"
            ),
            isSupported: true
        ),
        CardMetadata(
            id: "scapia-debit",
            issuer: "Scapia",
            name: "Scapia RuPay Debit Card",
            cardType: "rupay",
            variant: "debit",
            binRanges: [
                .init(start: "607846", end: "607846"),
                .init(start: "639344", end: "639344")
            ],
            imageURL: "https://www.scapia.com/images/dc-classic.png",
            details: .init(
                description: "Domestic debit card with online shopping and ATM access",
                features: ["ATM access in India", "Online shopping", "Bill payments", "Mobile recharge", "Insurance"],
                annualFee: nil,
                eligibility: "All account holders"
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
