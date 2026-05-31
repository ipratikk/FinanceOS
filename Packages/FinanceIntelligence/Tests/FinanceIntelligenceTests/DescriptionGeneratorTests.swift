@testable import FinanceIntelligence
import Foundation
import Testing

@Suite("DescriptionGenerator — fallback templates and description generation")
struct DescriptionGeneratorTests {
    private let generator = FallbackGenerator()
    private let descGenerator = DescriptionGenerator()

    // MARK: - Every intent produces a non-empty string

    @Test("All 21 intents produce non-empty descriptions")
    func allIntentsNonEmpty() {
        for intent in TransactionIntent.allCases {
            let context = DescriptionContext(
                merchantName: "Test Merchant",
                intent: intent,
                isDebit: true
            )
            let desc = generator.generate(from: context)
            #expect(!desc.isEmpty, "Intent \(intent.rawValue) produced empty description")
        }
    }

    // MARK: - Specific intent templates

    @Test("Salary intent includes merchant name and 'salary'")
    func salaryDescription() {
        let ctx = DescriptionContext(merchantName: "PayPal", intent: .salary, isDebit: false)
        let desc = generator.generate(from: ctx)
        #expect(desc.lowercased().contains("salary"))
        #expect(desc.contains("PayPal"))
    }

    @Test("Monthly subscription includes cadence prefix")
    func monthlySubscriptionDescription() {
        let ctx = DescriptionContext(
            merchantName: "Spotify", intent: .subscription,
            recurringCadence: .monthly, isRecurring: true
        )
        let desc = generator.generate(from: ctx)
        #expect(desc.lowercased().contains("monthly"))
        #expect(desc.contains("Spotify"))
    }

    @Test("Rent with landlord relationship routes correctly")
    func rentLandlordDescription() {
        let ctx = DescriptionContext(
            merchantName: "Ritik Gupta", intent: .transfer,
            relationship: .landlord,
            recurringCadence: .monthly, isRecurring: true, isDebit: true
        )
        let desc = generator.generate(from: ctx)
        #expect(desc.lowercased().contains("rent"))
        #expect(desc.contains("Ritik Gupta"))
    }

    @Test("Credit card payment includes merchant")
    func creditCardPaymentDescription() {
        let ctx = DescriptionContext(merchantName: "American Express", intent: .creditCardPayment)
        let desc = generator.generate(from: ctx)
        #expect(desc.lowercased().contains("credit card") || desc.lowercased().contains("payment"))
        #expect(desc.contains("American Express"))
    }

    @Test("Refund credit uses 'Refund from' phrasing")
    func refundDescription() {
        let ctx = DescriptionContext(merchantName: "Apple", intent: .refund, isDebit: false)
        let desc = generator.generate(from: ctx)
        #expect(desc.lowercased().contains("refund"))
    }

    @Test("Unknown intent with merchant falls back to payment phrasing")
    func unknownIntentWithMerchant() {
        let ctx = DescriptionContext(merchantName: "Some Bank", intent: .unknown, isDebit: true)
        let desc = generator.generate(from: ctx)
        #expect(!desc.isEmpty)
        #expect(desc.contains("Some Bank"))
    }

    @Test("Unknown intent without merchant produces generic string")
    func unknownIntentNoMerchant() {
        let ctx = DescriptionContext(merchantName: "", intent: .unknown, isDebit: true)
        let desc = generator.generate(from: ctx)
        #expect(!desc.isEmpty)
    }

    @Test("Cash withdrawal does not include merchant")
    func cashWithdrawalDescription() {
        let ctx = DescriptionContext(merchantName: "ATM", intent: .cashWithdrawal, isDebit: true)
        let desc = generator.generate(from: ctx)
        #expect(desc.lowercased().contains("atm") || desc.lowercased().contains("cash"))
    }

    // MARK: - DescriptionGenerator (async)

    @Test("DescriptionGenerator returns non-empty string for all intents")
    func asyncGeneratorNonEmpty() async {
        for intent in TransactionIntent.allCases {
            let ctx = DescriptionContext(merchantName: "Merchant", intent: intent)
            let desc = await descGenerator.generate(from: ctx)
            #expect(!desc.isEmpty, "Async generator produced empty string for \(intent.rawValue)")
        }
    }

    @Test("Sync fallback matches direct FallbackGenerator output")
    func syncFallbackMatchesDirect() {
        let ctx = DescriptionContext(merchantName: "Max Life", intent: .insurance)
        #expect(descGenerator.generateSync(from: ctx) == generator.generate(from: ctx))
    }

    // MARK: - Cadence prefix logic

    @Test("Annual cadence prefix applied correctly")
    func annualCadencePrefix() {
        let ctx = DescriptionContext(
            merchantName: "Max Life", intent: .insurance,
            recurringCadence: .yearly, isRecurring: true
        )
        let desc = generator.generate(from: ctx)
        #expect(desc.lowercased().contains("annual"))
    }

    @Test("Non-recurring transaction has no cadence prefix")
    func nonRecurringNoCadence() {
        let ctx = DescriptionContext(
            merchantName: "Blinkit", intent: .groceries,
            recurringCadence: .monthly, isRecurring: false
        )
        let desc = generator.generate(from: ctx)
        #expect(!desc.lowercased().contains("monthly"))
    }
}
