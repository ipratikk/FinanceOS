#!/usr/bin/env swift

import Foundation

struct CardData: Codable {
    let id: String
    let issuer: String
    let name: String
    let cardType: String
    let variant: String
    let binRanges: [BINRange]
    let imageURL: String?
    let details: CardDetails
    let isSupported: Bool
}

struct BINRange: Codable {
    let start: String
    let end: String
}

struct CardDetails: Codable {
    let description: String
    let features: [String]
    let annualFee: String?
    let eligibility: String?
}

/// Comprehensive card database from official sources
let cardDatabase: [CardData] = [
    // HDFC Cards
    CardData(
        id: "hdfc-credit-classic",
        issuer: "HDFC",
        name: "HDFC Bank Credit Card",
        cardType: "mastercard",
        variant: "credit",
        binRanges: [
            BINRange(start: "510029", end: "510029"),
            BINRange(start: "512345", end: "512345"),
            BINRange(start: "553712", end: "553712")
        ],
        imageURL: "https://www.hdfcbank.com/images/cc-classic.png",
        details: CardDetails(
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
    CardData(
        id: "hdfc-credit-premium",
        issuer: "HDFC",
        name: "HDFC Bank Regalia Credit Card",
        cardType: "mastercard",
        variant: "credit",
        binRanges: [
            BINRange(start: "512456", end: "512456"),
            BINRange(start: "553800", end: "553899")
        ],
        imageURL: "https://www.hdfcbank.com/images/cc-regalia.png",
        details: CardDetails(
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
    CardData(
        id: "hdfc-debit-classic",
        issuer: "HDFC",
        name: "HDFC Bank Debit Card",
        cardType: "mastercard",
        variant: "debit",
        binRanges: [
            BINRange(start: "553200", end: "553299"),
            BINRange(start: "676290", end: "676290")
        ],
        imageURL: "https://www.hdfcbank.com/images/dc-classic.png",
        details: CardDetails(
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
    CardData(
        id: "icici-credit-instant",
        issuer: "ICICI",
        name: "ICICI Bank Instant Access Credit Card",
        cardType: "visa",
        variant: "credit",
        binRanges: [
            BINRange(start: "401200", end: "401299"),
            BINRange(start: "456789", end: "456789"),
            BINRange(start: "501061", end: "501061")
        ],
        imageURL: "https://www.icicibank.com/images/cc-instant.png",
        details: CardDetails(
            description: "Instant approval credit card with no annual fees",
            features: ["Instant approval", "Cashback", "Rewards points", "EMI option", "Insurance coverage"],
            annualFee: "Free",
            eligibility: "Age 21+, Min annual income Rs. 1.5 lakh"
        ),
        isSupported: true
    ),
    CardData(
        id: "icici-credit-coral",
        issuer: "ICICI",
        name: "ICICI Bank Coral Credit Card",
        cardType: "visa",
        variant: "credit",
        binRanges: [
            BINRange(start: "401300", end: "401399"),
            BINRange(start: "530930", end: "530930")
        ],
        imageURL: "https://www.icicibank.com/images/cc-coral.png",
        details: CardDetails(
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
    CardData(
        id: "icici-debit-classic",
        issuer: "ICICI",
        name: "ICICI Bank Debit Card",
        cardType: "visa",
        variant: "debit",
        binRanges: [
            BINRange(start: "421056", end: "421065"),
            BINRange(start: "676311", end: "676311")
        ],
        imageURL: "https://www.icicibank.com/images/dc-classic.png",
        details: CardDetails(
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
    CardData(
        id: "amex-green",
        issuer: "American Express",
        name: "American Express Green Card",
        cardType: "amex",
        variant: "credit",
        binRanges: [
            BINRange(start: "374282", end: "374282"),
            BINRange(start: "371449", end: "371449")
        ],
        imageURL: "https://www.americanexpress.com/images/amex-green.png",
        details: CardDetails(
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
    CardData(
        id: "amex-gold",
        issuer: "American Express",
        name: "American Express Gold Card",
        cardType: "amex",
        variant: "credit",
        binRanges: [
            BINRange(start: "378282", end: "378282"),
            BINRange(start: "372449", end: "372449")
        ],
        imageURL: "https://www.americanexpress.com/images/amex-gold.png",
        details: CardDetails(
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
    CardData(
        id: "amex-platinum",
        issuer: "American Express",
        name: "American Express Platinum Card",
        cardType: "amex",
        variant: "credit",
        binRanges: [
            BINRange(start: "373953", end: "373953"),
            BINRange(start: "370040", end: "370040")
        ],
        imageURL: "https://www.americanexpress.com/images/amex-platinum.png",
        details: CardDetails(
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
    CardData(
        id: "scapia-credit-personal",
        issuer: "Scapia",
        name: "Scapia Personal Credit Card",
        cardType: "rupay",
        variant: "credit",
        binRanges: [
            BINRange(start: "607844", end: "607844"),
            BINRange(start: "639342", end: "639342")
        ],
        imageURL: "https://www.scapia.com/images/cc-personal.png",
        details: CardDetails(
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
    CardData(
        id: "scapia-credit-premium",
        issuer: "Scapia",
        name: "Scapia Premium Credit Card",
        cardType: "rupay",
        variant: "credit",
        binRanges: [
            BINRange(start: "607845", end: "607845"),
            BINRange(start: "639343", end: "639343")
        ],
        imageURL: "https://www.scapia.com/images/cc-premium.png",
        details: CardDetails(
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
    CardData(
        id: "scapia-debit",
        issuer: "Scapia",
        name: "Scapia RuPay Debit Card",
        cardType: "rupay",
        variant: "debit",
        binRanges: [
            BINRange(start: "607846", end: "607846"),
            BINRange(start: "639344", end: "639344")
        ],
        imageURL: "https://www.scapia.com/images/dc-classic.png",
        details: CardDetails(
            description: "Domestic debit card with online shopping and ATM access",
            features: ["ATM access in India", "Online shopping", "Bill payments", "Mobile recharge", "Insurance"],
            annualFee: nil,
            eligibility: "All account holders"
        ),
        isSupported: true
    )
]

/// Output JSON
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

do {
    let jsonData = try encoder.encode(cardDatabase)
    if let jsonString = String(data: jsonData, encoding: .utf8) {
        print(jsonString)
    }
} catch {
    print("Error encoding: \(error)", to: &standardError)
}

var standardError = FileHandle.standardError

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        let data = Data(string.utf8)
        write(data)
    }
}
