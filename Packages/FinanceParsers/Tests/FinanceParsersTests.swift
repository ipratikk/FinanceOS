@testable import FinanceParsers
import Foundation
import Testing

// MARK: - Fixture helpers

private func fixtureURL(_ name: String) throws -> URL {
    let bundle = Bundle.module
    guard let url = bundle.url(forResource: name, withExtension: nil) else {
        throw TestError.missingFixture(name)
    }
    return url
}

private enum TestError: Error {
    case missingFixture(String)
}

// MARK: - Detection tests

@Test
func fileTypeDetector_csv_detected() throws {
    let url = URL(fileURLWithPath: "/tmp/statement.csv")
    let type = try FileTypeDetector.detect(fileURL: url)
    #expect(type == .csv)
}

@Test
func fileTypeDetector_txt_detected() throws {
    let url = URL(fileURLWithPath: "/tmp/statement.txt")
    let type = try FileTypeDetector.detect(fileURL: url)
    #expect(type == .txt)
}

@Test
func fileTypeDetector_unknown_throws() {
    let url = URL(fileURLWithPath: "/tmp/statement.xlsx")
    #expect(throws: (any Error).self) {
        try FileTypeDetector.detect(fileURL: url)
    }
}

@Test
func fileTypeDetector_pdf_throws() {
    let url = URL(fileURLWithPath: "/tmp/statement.pdf")
    #expect(throws: (any Error).self) {
        try FileTypeDetector.detect(fileURL: url)
    }
}

// MARK: - HDFC Bank (TXT) parser

@Test
func hdfcBank_parsesTransactionCount() throws {
    let url = try fixtureURL("hdfc_bank.txt")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .hdfcBank)
    #expect(result.statement.transactions.count == 4)
}

@Test
func hdfcBank_debitHasPositiveAmount() throws {
    let url = try fixtureURL("hdfc_bank.txt")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .hdfcBank)
    let grocery = try #require(result.statement.transactions.first {
        $0.description.contains("Grocery")
    })
    #expect(grocery.amountMinorUnits == 50000, "debit should be positive 500.00 → 50000 minor units")
}

@Test
func hdfcBank_creditHasNegativeAmount() throws {
    let url = try fixtureURL("hdfc_bank.txt")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .hdfcBank)
    let salary = try #require(result.statement.transactions.first {
        $0.description.contains("Salary")
    })
    #expect(salary.amountMinorUnits == -5_000_000, "credit should be negative 50000.00 → -5000000 minor units")
}

@Test
func hdfcBank_refundIsCredit() throws {
    let url = try fixtureURL("hdfc_bank.txt")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .hdfcBank)
    let refund = try #require(result.statement.transactions.first {
        $0.description.contains("Refund")
    })
    #expect(refund.amountMinorUnits < 0, "refund credit should have negative amount")
}

@Test
func hdfcBank_bankNameSet() throws {
    let url = try fixtureURL("hdfc_bank.txt")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .hdfcBank)
    #expect(result.statement.bankName == "HDFC")
}

@Test
func hdfcBank_fingerprintsAreUnique() throws {
    let url = try fixtureURL("hdfc_bank.txt")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .hdfcBank)
    let fps = result.statement.transactions.compactMap(\.sourceFingerprint)
    #expect(Set(fps).count == fps.count, "all fingerprints must be unique")
}

// MARK: - HDFC Card (CSV) parser

@Test
func hdfcCard_parsesTransactionCount() throws {
    let url = try fixtureURL("hdfc_card.csv")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .hdfcCard)
    #expect(result.statement.transactions.count == 4)
}

@Test
func hdfcCard_debitHasPositiveAmount() throws {
    let url = try fixtureURL("hdfc_card.csv")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .hdfcCard)
    let swiggy = try #require(result.statement.transactions.first { $0.description.contains("Swiggy") })
    #expect(swiggy.amountMinorUnits == 35000, "350.00 debit → 35000 minor units")
}

@Test
func hdfcCard_creditIsNegative() throws {
    let url = try fixtureURL("hdfc_card.csv")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .hdfcCard)
    let refund = try #require(result.statement.transactions.first { $0.description.contains("Refund") })
    #expect(refund.amountMinorUnits == -50000, "500.00 credit → -50000 minor units")
}

@Test
func hdfcCard_fingerprintsAreUnique() throws {
    let url = try fixtureURL("hdfc_card.csv")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .hdfcCard)
    let fps = result.statement.transactions.compactMap(\.sourceFingerprint)
    #expect(Set(fps).count == fps.count)
}

// MARK: - ICICI Bank (CSV) parser

@Test
func iciciBank_parsesTransactionCount() throws {
    let url = try fixtureURL("icici_bank.csv")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .iciciBank)
    #expect(result.statement.transactions.count == 4)
}

@Test
func iciciBank_withdrawalIsPositive() throws {
    let url = try fixtureURL("icici_bank.csv")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .iciciBank)
    let atm = try #require(result.statement.transactions.first { $0.description.contains("ATM") })
    #expect(atm.amountMinorUnits == 200_000, "2000.00 withdrawal → 200000 minor units")
}

@Test
func iciciBank_depositIsNegative() throws {
    let url = try fixtureURL("icici_bank.csv")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .iciciBank)
    let salary = try #require(result.statement.transactions.first { $0.description.contains("Salary") })
    #expect(salary.amountMinorUnits == -5_000_000, "50000.00 credit → -5000000 minor units")
}

@Test
func iciciBank_fingerprintsAreUnique() throws {
    let url = try fixtureURL("icici_bank.csv")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .iciciBank)
    let fps = result.statement.transactions.compactMap(\.sourceFingerprint)
    #expect(Set(fps).count == fps.count)
}

// MARK: - ICICI Card (CSV) parser

@Test
func iciciCard_parsesTransactionCount() throws {
    let url = try fixtureURL("icici_card.csv")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .iciciCard)
    #expect(result.statement.transactions.count == 4)
}

@Test
func iciciCard_drIsPositive() throws {
    let url = try fixtureURL("icici_card.csv")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .iciciCard)
    let swiggy = try #require(result.statement.transactions.first { $0.description.contains("Swiggy") })
    #expect(swiggy.amountMinorUnits == 35000)
}

@Test
func iciciCard_crIsNegative() throws {
    let url = try fixtureURL("icici_card.csv")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .iciciCard)
    let refund = try #require(result.statement.transactions.first { $0.description.contains("Refund") })
    #expect(refund.amountMinorUnits == -50000)
}

// MARK: - Amex Card (CSV) parser

@Test
func amex_parsesTransactionCount() throws {
    let url = try fixtureURL("amex_card.csv")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .amex)
    #expect(result.statement.transactions.count == 4)
}

@Test
func amex_positiveAmountIsDebit() throws {
    let url = try fixtureURL("amex_card.csv")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .amex)
    let amazon = try #require(result.statement.transactions.first { $0.description.contains("Amazon") })
    #expect(amazon.amountMinorUnits == 150_000, "1500.00 → 150000 minor units")
}

@Test
func amex_negativeAmountIsCredit() throws {
    let url = try fixtureURL("amex_card.csv")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .amex)
    let refund = try #require(result.statement.transactions.first { $0.description.contains("Refund") })
    #expect(refund.amountMinorUnits == -64900, "-649.00 → -64900 minor units")
}

@Test
func amex_fingerprintsAreUnique() throws {
    let url = try fixtureURL("amex_card.csv")
    let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: .amex)
    let fps = result.statement.transactions.compactMap(\.sourceFingerprint)
    #expect(Set(fps).count == fps.count)
}

// MARK: - Negative tests

@Test
func parser_unsupportedExtensionThrows() {
    let url = URL(fileURLWithPath: "/tmp/statement.docx")
    #expect(throws: (any Error).self) {
        try StatementDetector.detect(fileURL: url)
    }
}

@Test
func parser_emptyFileThrows() throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("empty.txt")
    try "".write(to: tmp, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: tmp) }

    #expect(throws: (any Error).self) {
        try UnifiedStatementParser().parse(fileURL: tmp, detectedSource: .hdfcBank)
    }
}

@Test
func parser_malformedCSVMissingRequiredColumns() throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("malformed.csv")
    try "foo,bar,baz\n1,2,3\n".write(to: tmp, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: tmp) }

    let result = try? UnifiedStatementParser().parse(fileURL: tmp, detectedSource: .iciciBank)
    let count = result?.statement.transactions.count ?? 0
    #expect(count == 0, "malformed CSV with wrong columns should produce zero transactions")
}

@Test
func parser_invalidDateRowSkipped() throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("baddates.txt")
    let content = """
    Date,Narration,Value Dat,Debit Amount,Credit Amount,Chq/Ref Number,Closing Balance
    NOT-A-DATE,Some Txn,01/04/26,500.00,,,49500.00
    01/04/26,Valid Txn,01/04/26,100.00,,,49400.00
    """
    try content.write(to: tmp, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: tmp) }

    let result = try UnifiedStatementParser().parse(fileURL: tmp, detectedSource: .hdfcBank)
    #expect(result.statement.transactions.count == 1, "row with invalid date must be skipped")
}

// MARK: - Legacy stub test

@Test
func parserExists() {
    let parser = HDFCPDFParser()
    #expect(parser.supportedFormat == .pdf)
}
