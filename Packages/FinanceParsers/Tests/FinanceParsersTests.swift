@testable import FinanceParsers
import Foundation
import Testing

@Test
func parserExists() {
    let parser = HDFCPDFParser()
    #expect(parser.supportedFormat == .pdf)
}

@Test
func fixtureParsing() async throws {
    let fileManager = FileManager.default
    let currentDir = fileManager.currentDirectoryPath
    let fixtureURL = URL(fileURLWithPath: currentDir).appendingPathComponent("Packages/FinanceParsers/Tests/Fixtures/HDFC")

    guard fileManager.fileExists(atPath: fixtureURL.path) else {
        throw NSError(domain: "FixtureMissing", code: 1)
    }

    guard let files = try? fileManager.contentsOfDirectory(at: fixtureURL, includingPropertiesForKeys: nil) else {
        throw NSError(domain: "FixturesUnavailable", code: 2)
    }

    let pdfFiles = files.filter { $0.pathExtension.lowercased() == "pdf" }
    #expect(pdfFiles.count > 0)

    for pdfFile in pdfFiles {
        let parser = HDFCPDFParser()
        do {
            let statement = try await parser.parseStatement(from: pdfFile)

            #expect(statement.bankName == "HDFC")
            #expect(statement.transactions.count > 0)

            // Verify transactions have required fields
            for txn in statement.transactions {
                #expect(!txn.description.isEmpty)
                #expect(txn.amountMinorUnits != 0)
            }
        } catch let error as TransactionImportError {
            if case .passwordProtected = error {
                print("⚠️  Skipping password-protected PDF")
            }
        }
    }
}
