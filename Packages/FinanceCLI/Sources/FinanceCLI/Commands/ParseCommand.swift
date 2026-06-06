import ArgumentParser
import FinanceParsers
import Foundation

struct ParseCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "parse",
        abstract: "Parse a bank statement and print normalized transactions"
    )

    @Argument(help: "Path to the statement file (CSV or XLSX)")
    var filePath: String

    @Flag(name: .long, help: "Output as JSON instead of human-readable")
    var json: Bool = false

    func run() async throws {
        let url = URL(fileURLWithPath: filePath)
        let source = try StatementDetector.detect(fileURL: url)
        let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: source)
        let statement = result.statement

        if json {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(statement)
            print(String(data: data, encoding: .utf8) ?? "")
        } else {
            print("Bank: \(statement.bankName)")
            print("Account: \(statement.accountName)")
            print("Transactions: \(statement.transactions.count)")
            print("")
            for txn in statement.transactions {
                let amount = String(format: "%.2f", Double(abs(txn.amountMinorUnits)) / 100.0)
                let sign = txn.amountMinorUnits >= 0 ? "+" : "-"
                print("  \(txn.postedAt)  \(sign)\(amount)  \(txn.description)")
            }
        }
    }
}
