@testable import FinanceParsers
import XCTest

final class FinanceParsersTests: XCTestCase {
    func testParserExists() {
        let parser = HDFCPDFParser()
        XCTAssertEqual(parser.supportedFormat, .pdf)
    }

    func testFixtureParsing() async throws {
        let bundle = Bundle.module
        guard let fixturePath = bundle.path(forResource: "Fixtures/HDFC", ofType: nil) else {
            XCTSkip("Fixtures not found")
        }

        let fixtureURL = URL(fileURLWithPath: fixturePath)
        let fileManager = FileManager.default

        guard let files = try? fileManager.contentsOfDirectory(at: fixtureURL, includingPropertiesForKeys: nil) else {
            XCTSkip("No fixtures available")
        }

        let pdfFiles = files.filter { $0.pathExtension.lowercased() == "pdf" }
        XCTAssertGreater(pdfFiles.count, 0, "No PDF fixtures found")

        for pdfFile in pdfFiles {
            do {
                let parser = HDFCPDFParser()
                let statement = try await parser.parseStatement(from: pdfFile)

                XCTAssertEqual(statement.bankName, "HDFC")
                XCTAssertGreater(
                    statement.transactions.count,
                    0,
                    "No transactions parsed from \(pdfFile.lastPathComponent)"
                )

                // Verify transactions have required fields
                for txn in statement.transactions {
                    XCTAssertFalse(txn.description.isEmpty, "Transaction has empty description")
                    XCTAssertNotEqual(txn.amountMinorUnits, 0, "Transaction has zero amount")
                }
            } catch let error as TransactionImportError {
                if case .passwordProtected = error {
                    print("⚠️  Skipping password-protected PDF: \(pdfFile.lastPathComponent)")
                } else {
                    XCTFail("Failed to parse \(pdfFile.lastPathComponent): \(error.description)")
                }
            }
        }
    }
}
