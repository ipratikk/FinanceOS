@testable import FinanceIntelligence
import Foundation
import Testing

@Suite("DescriptionGenerator — deterministic, truthful, name-centric output")
struct DescriptionGeneratorTests {
    private let generator = FallbackGenerator()
    private let descGenerator = DescriptionGenerator()

    // MARK: - Always non-empty

    @Test("All 21 intents produce non-empty descriptions")
    func allIntentsNonEmpty() {
        for intent in TransactionIntent.allCases {
            let context = DescriptionContext(merchantName: "Test Merchant", intent: intent, isDebit: true)
            let desc = generator.generate(from: context)
            #expect(!desc.isEmpty, "Intent \(intent.rawValue) produced empty description")
        }
    }

    // MARK: - Name is the description (no invented activity)

    @Test("Merchant name is the description regardless of intent")
    func merchantNameIsDescription() {
        for intent in [TransactionIntent.subscription, .groceries, .shopping, .food, .insurance] {
            let ctx = DescriptionContext(merchantName: "Spotify", intent: intent)
            #expect(generator.generate(from: ctx) == "Spotify")
        }
    }

    @Test("No invented activity nouns appended to a name")
    func noInventedActivity() {
        let ctx = DescriptionContext(merchantName: "Seema Goel", intent: .unknown, isDebit: true)
        let desc = generator.generate(from: ctx)
        #expect(desc == "Seema Goel")
        #expect(!desc.lowercased().contains("grocery"))
        #expect(!desc.lowercased().contains("shopping"))
    }

    @Test("Empty merchant falls back to direction-only label")
    func emptyMerchantDebit() {
        let ctx = DescriptionContext(merchantName: "", intent: .unknown, isDebit: true)
        #expect(generator.generate(from: ctx) == "Debit transaction")
    }

    @Test("Empty merchant credit falls back to credit label")
    func emptyMerchantCredit() {
        let ctx = DescriptionContext(merchantName: "", intent: .unknown, isDebit: false)
        #expect(generator.generate(from: ctx) == "Credit transaction")
    }

    // MARK: - ATM special case (no useful counterparty)

    @Test("Cash withdrawal uses ATM label, not merchant")
    func cashWithdrawalLabel() {
        let ctx = DescriptionContext(merchantName: "ATM", intent: .cashWithdrawal, isDebit: true)
        #expect(generator.generate(from: ctx) == "ATM Cash Withdrawal")
    }

    // MARK: - Transfers render as the bare counterparty name

    @Test("Transfer renders as just the counterparty name")
    func transferJustName() {
        // Rent/salary labels come from RawPatternParser (raw keywords), not from relationship here.
        for relationship in [RelationshipType?.none, .friend, .landlord, .employer] {
            let ctx = DescriptionContext(
                merchantName: "Ritik Gupta", intent: .transfer,
                relationship: relationship, isDebit: true
            )
            #expect(generator.generate(from: ctx) == "Ritik Gupta")
        }
    }

    // MARK: - DescriptionGenerator parity and async path

    @Test("Async generate equals sync generate")
    func asyncEqualsSync() async {
        for intent in TransactionIntent.allCases {
            let ctx = DescriptionContext(merchantName: "Merchant", intent: intent)
            let asyncDesc = await descGenerator.generate(from: ctx)
            #expect(asyncDesc == descGenerator.generateSync(from: ctx))
        }
    }

    @Test("Sync generation matches direct FallbackGenerator for plain cases")
    func syncMatchesFallback() {
        let ctx = DescriptionContext(merchantName: "Max Life Insurance", intent: .insurance)
        #expect(descGenerator.generateSync(from: ctx) == generator.generate(from: ctx))
    }

    // MARK: - RawPatternParser wired through DescriptionGenerator (Tier 1)

    @Test("INW raw description produces structured remittance label")
    func inwThroughGenerator() {
        let ctx = DescriptionContext(
            merchantName: "", intent: .unknown,
            rawDescription: "INW 050526I049903643 USD2382.62@95.2648"
        )
        let desc = descGenerator.generateSync(from: ctx)
        #expect(desc.hasPrefix("Inward Remittance"))
        #expect(desc.contains("$2,382.62"))
    }

    @Test("NEFT salary raw description produces salary label")
    func neftSalaryThroughGenerator() {
        let raw = "NEFT CR-BOFA0CN6215-PAYPAL INDIA PVT LTD-PRATIK GOEL-BOFAN52025052305477261 SALARY FOR MAY 2025"
        let ctx = DescriptionContext(
            merchantName: "PayPal India", intent: .unknown, rawDescription: raw
        )
        let desc = descGenerator.generateSync(from: ctx)
        #expect(desc == "Salary from PayPal India · May 2025")
    }

    @Test("HOUSE RENT raw description produces rent label over bare name")
    func rentRawThroughGenerator() {
        let raw = "NEFT DR-ICIC0001283-SEEMA GOEL-NETBANK,MUM-HDFCN52025103063065156-HOUSE RENT"
        let ctx = DescriptionContext(
            merchantName: "Seema Goel", intent: .unknown, rawDescription: raw
        )
        #expect(descGenerator.generateSync(from: ctx) == "House Rent · Seema Goel")
    }

    @Test("Raw pattern takes priority over relationship and intent")
    func rawPriorityOverFallback() {
        let ctx = DescriptionContext(
            merchantName: "Random Merchant", intent: .transfer,
            relationship: .friend,
            rawDescription: "050526I049903643 DPO2712595243131 IGST"
        )
        #expect(descGenerator.generateSync(from: ctx) == "IGST on Wire Transfer")
    }
}
