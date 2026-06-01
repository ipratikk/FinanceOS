import FinanceCore
@testable import FinanceIntelligence
import Foundation
import Testing

// MARK: - Fixture Types

private struct GoldenFixture: Decodable {
    let version: String
    let examples: [GoldenExample]
}

private struct GoldenExample: Decodable {
    let id: String
    let group: String
    let narration: String
    let amountMinorUnits: Int64
    let isDebit: Bool
    let expected: ExpectedResult

    struct ExpectedResult: Decodable {
        let categoryId: String
        let intentId: String
        let isPersonTransfer: Bool
    }
}

// MARK: - Benchmark

/// CI-blocking regression test for categorization, intent detection, and person transfer classification.
///
/// Strict assertions (fail build): `categoryId`, `intentId`, `isPersonTransfer`.
/// Non-blocking (logged only): `confidence`, merchant name resolution.
///
/// Adding a new bank parser: include ≥2 golden examples for that parser in the relevant group.
@Suite("GoldenTransactionBenchmark")
struct GoldenTransactionBenchmarkTests {
    private let extractor = TransactionFeatureExtractor()
    private let normalizer = MerchantNormalizer()
    private let ruleCategorizer = RuleBasedCategorizer()
    private let ruleEngine = RuleEngine()
    private let personResolver = PersonResolver()

    @Test("All 50 golden transactions pass strict assertions")
    func allGoldenTransactionsPassStrictAssertions() throws {
        let fixture = try loadFixture()
        #expect(fixture.examples.count >= 50, "golden_transactions.json must have ≥50 examples")

        var failures: [String] = []
        for example in fixture.examples {
            let result = classify(example)
            if result.categoryId != example.expected.categoryId {
                failures.append(
                    "[\(example.id)] categoryId: expected=\(example.expected.categoryId) got=\(result.categoryId)"
                )
            }
            if result.intentId != example.expected.intentId {
                failures.append(
                    "[\(example.id)] intentId: expected=\(example.expected.intentId) got=\(result.intentId)"
                )
            }
            if result.isPersonTransfer != example.expected.isPersonTransfer {
                failures.append(
                    "[\(example.id)] isPersonTransfer: expected=\(example.expected.isPersonTransfer) " +
                        "got=\(result.isPersonTransfer)"
                )
            }
        }
        #expect(failures.isEmpty, Comment(rawValue: failures.joined(separator: "\n")))
    }

    @Test("UPI merchant group: all 10 examples not classified as person transfers")
    func upiMerchantsNotPersonTransfers() throws {
        let fixture = try loadFixture()
        let merchants = fixture.examples.filter { $0.group == "upi_merchant" }
        #expect(merchants.count == 10)
        for example in merchants {
            let isPersonTransfer = personResolver.resolve(example.narration) != nil
            #expect(!isPersonTransfer, "[\(example.id)] should not be a person transfer")
        }
    }

    @Test("UPI person group: all 10 examples classified as person transfers")
    func upiPersonsArePersonTransfers() throws {
        let fixture = try loadFixture()
        let persons = fixture.examples.filter { $0.group == "upi_person" }
        #expect(persons.count == 10)
        for example in persons {
            let isPersonTransfer = personResolver.resolve(example.narration) != nil
            #expect(isPersonTransfer, "[\(example.id)] should be a person transfer")
        }
    }

    @Test("Salary group: all 5 examples yield income categoryId and salary intentId")
    func salaryExamplesYieldIncomeCategory() throws {
        let fixture = try loadFixture()
        let salaries = fixture.examples.filter { $0.group == "salary" }
        #expect(salaries.count == 5)
        for example in salaries {
            let result = classify(example)
            #expect(result.categoryId == "income", "[\(example.id)] expected income, got \(result.categoryId)")
            #expect(result.intentId == "salary", "[\(example.id)] expected salary intent, got \(result.intentId)")
        }
    }

    @Test("ATM group: all 5 examples yield atm categoryId and cash_withdrawal intentId")
    func atmExamplesYieldAtmCategory() throws {
        let fixture = try loadFixture()
        let atms = fixture.examples.filter { $0.group == "atm" }
        #expect(atms.count == 5)
        for example in atms {
            let result = classify(example)
            #expect(result.categoryId == "atm", "[\(example.id)] expected atm, got \(result.categoryId)")
            #expect(
                result.intentId == "cash_withdrawal",
                "[\(example.id)] expected cash_withdrawal, got \(result.intentId)"
            )
        }
    }

    @Test("SIP/NACH group: all 5 examples yield investments categoryId")
    func sipExamplesYieldInvestmentsCategory() throws {
        let fixture = try loadFixture()
        let sips = fixture.examples.filter { $0.group == "sip_nach" }
        #expect(sips.count == 5)
        for example in sips {
            let result = classify(example)
            let got = result.categoryId
            #expect(got == "investments", "[\(example.id)] expected investments, got \(got)")
        }
    }

    // MARK: - Private Helpers

    private struct ClassificationResult {
        let categoryId: String
        let intentId: String
        let isPersonTransfer: Bool
    }

    private func classify(_ example: GoldenExample) -> ClassificationResult {
        let txn = Transaction(
            postedAt: Date(timeIntervalSince1970: 1_748_736_000),
            description: example.narration,
            amountMinorUnits: example.amountMinorUnits,
            currencyCode: "INR",
            transactionType: example.isDebit ? .debit : .credit
        )
        let features = extractor.extract(from: txn, context: .empty)
        let merchantCandidate = normalizer.normalize(example.narration)
        let ruleResult = ruleEngine.evaluate(features)

        let categoryId: String = if let merchantCatId = merchantCandidate.categoryId {
            // Alias table hit — mirrors `predictCategory` priority 4 (alias before rule fallback).
            merchantCatId.components(separatedBy: ".").first ?? merchantCatId
        } else if let ruleCat = ruleResult.categoryPrediction, ruleCat.confidence >= 0.92 {
            // High-confidence structural rule (salary, ATM, SIP, billpay, transfer) — mirrors analyzeEnriched.
            ruleCat.categoryId
        } else {
            ruleCategorizer.categorize(features).categoryId
        }

        return ClassificationResult(
            categoryId: categoryId,
            intentId: ruleResult.intentPrediction.intent.rawValue,
            isPersonTransfer: personResolver.resolve(example.narration) != nil
        )
    }

    private func loadFixture() throws -> GoldenFixture {
        guard let url = Bundle.module.url(forResource: "golden_transactions", withExtension: "json") else {
            Issue.record("golden_transactions.json not found in test bundle")
            throw URLError(.fileDoesNotExist)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(GoldenFixture.self, from: data)
    }
}
