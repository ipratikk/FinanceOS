import ArgumentParser
import FinanceCore
import FinanceParsers
import Foundation

@available(macOS 10.15, *)
struct ImportCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "import",
        abstract: "Parse and import statement(s) into the FinanceOS database"
    )

    @Argument(help: "Path(s) to statement files")
    var filePaths: [String]

    @Option(name: .long, help: "Override database path")
    var dbPath: String?

    func run() async throws {
        if let dbPath {
            DatabaseManager.configure(url: URL(fileURLWithPath: dbPath))
        }

        let container = await AppContainer.shared
        let ledgers = try await container.ledgerRepository.fetchLedgers()
        let banks = try await container.bankRepository.fetchBanks()

        for path in filePaths {
            let url = URL(fileURLWithPath: path)
            do {
                let source = try StatementDetector.detect(fileURL: url)
                let result = try UnifiedStatementParser().parse(fileURL: url, detectedSource: source)
                let statement = result.statement
                guard let target = ImportTargetMatcher.bestTarget(
                    for: statement,
                    ledgers: ledgers,
                    banks: banks
                ) else {
                    CLIProgressReporter.error("[\(url.lastPathComponent)] no matching ledger — skipping")
                    continue
                }
                let ledgerKind: LedgerKind = statement.cardLast4 != nil ? .creditCard : .bankAccount
                let context = OperationContext(name: "cli-import")
                let importResult = try await container.transactionImportPipeline.execute(
                    statement: statement,
                    target: target,
                    ledgerKind: ledgerKind,
                    context: context
                )
                CLIProgressReporter.report(
                    "[\(url.lastPathComponent)] imported: \(importResult.inserted), duplicates: \(importResult.skipped)"
                )
            } catch {
                CLIProgressReporter.error("[\(url.lastPathComponent)] \(error.localizedDescription)")
            }
        }
    }
}
