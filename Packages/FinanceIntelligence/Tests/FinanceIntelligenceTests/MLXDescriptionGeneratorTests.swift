@testable import FinanceIntelligence
import Foundation
import Testing

@Suite("MLXDescriptionGenerator — templates, factuality, batching")
struct MLXDescriptionGeneratorTests {
    let gen = MLXDescriptionGenerator()
    let sampleDate = ISO8601DateFormatter().date(from: "2026-05-15T10:00:00Z") ?? Date(timeIntervalSince1970: 0)

    private func input(
        merchant: String = "Zepto", category: String = "groceries",
        amount: Int = 34900, isDebit: Bool = true
    ) -> MLXDescriptionInput {
        MLXDescriptionInput(
            merchant: merchant, categoryId: category,
            amountMinorUnits: amount, date: sampleDate,
            narration: "UPI-ZEPTO", isDebit: isDebit
        )
    }

    // MARK: - Template

    @Test("Debit description includes amount, merchant, category")
    func debitDescription() async {
        let result = await gen.generate(from: input())
        #expect(result.description.contains("349"))
        #expect(result.description.contains("Zepto"))
        #expect(result.description.contains("groceries"))
        #expect(result.source == .template)
    }

    @Test("Credit description uses 'received' phrasing")
    func creditDescription() async {
        let result = await gen.generate(from: input(merchant: "Employer", isDebit: false))
        #expect(result.description.contains("received"))
        #expect(result.description.contains("Employer"))
    }

    @Test("Amount formatting: whole rupees")
    func amountFormattingWholeRupees() async {
        let result = await gen.generate(from: input(amount: 34900))
        #expect(result.description.contains("349"))
    }

    @Test("Amount formatting: with paise")
    func amountFormattingWithPaise() async {
        let inp = MLXDescriptionInput(
            merchant: "Swiggy", categoryId: "food",
            amountMinorUnits: 34950, date: sampleDate,
            narration: "UPI-SWIGGY", isDebit: true
        )
        let result = await gen.generate(from: inp)
        #expect(result.description.contains("349.50"))
    }

    @Test("Description is always non-empty")
    func nonEmptyDescription() async {
        let result = await gen.generate(from: input(merchant: "", category: "", amount: 0))
        #expect(!result.description.isEmpty)
    }

    @Test("isFactuallyVerified always true for template path")
    func templateAlwaysVerified() async {
        let result = await gen.generate(from: input())
        #expect(result.isFactuallyVerified == true)
    }

    // MARK: - Factuality Guard

    @Test("verifiedDescription rejects output missing amount")
    func factualityRejectsNoAmount() async {
        let inp = input(amount: 34900)
        let rejected = await gen.verifiedDescription("You went shopping at Zepto.", input: inp)
        #expect(rejected == nil)
    }

    @Test("verifiedDescription rejects output missing merchant")
    func factualityRejectsNoMerchant() async {
        let inp = input()
        let rejected = await gen.verifiedDescription("You paid 349 for groceries.", input: inp)
        #expect(rejected == nil)
    }

    @Test("verifiedDescription accepts output with both amount and merchant")
    func factualityAcceptsValid() async {
        let inp = input()
        let accepted = await gen.verifiedDescription("You paid 349 at Zepto for groceries.", input: inp)
        #expect(accepted != nil)
    }

    // MARK: - Batch

    @Test("Batch processes max 50 inputs")
    func batchMaxSize() async {
        let inputs = (0 ..< 60).map { i in
            MLXDescriptionInput(
                merchant: "M\(i)", categoryId: "cat",
                amountMinorUnits: 10000, date: sampleDate,
                narration: "N\(i)", isDebit: true
            )
        }
        let results = await gen.generateBatch(inputs)
        #expect(results.count == 50)
    }

    @Test("Batch returns result for each input")
    func batchResultsNonEmpty() async {
        let inputs = [input(), input(merchant: "Swiggy"), input(merchant: "Uber")]
        let results = await gen.generateBatch(inputs)
        #expect(results.count == 3)
        #expect(results.allSatisfy { !$0.description.isEmpty })
    }

    @Test("Max batch size constant is 50")
    func batchSizeConstant() {
        #expect(MLXDescriptionGenerator.maxBatchSize == 50)
    }
}
