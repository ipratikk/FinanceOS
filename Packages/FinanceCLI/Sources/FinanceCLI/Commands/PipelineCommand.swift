import ArgumentParser
import FinanceCore
import FinanceIntelligence
import FinanceParsers
import Foundation

struct PipelineCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pipeline",
        abstract: "Full end-to-end: parse → import → analyze"
    )

    @Argument(help: "Path(s) to statement files")
    var filePaths: [String]

    @Option(name: .long, help: "Override database path")
    var dbPath: String?

    @Flag(name: .long, help: "Skip intelligence categorization step")
    var skipAnalysis: Bool = false

    func run() async throws {
        if let dbPath {
            DatabaseManager.configure(url: URL(fileURLWithPath: dbPath))
        }

        let container = await AppContainer.shared
        let ledgers = try await container.ledgerRepository.fetchLedgers()
        let banks = try await container.bankRepository.fetchBanks()
        var importedCount = 0

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
                let context = OperationContext(name: "cli-pipeline")
                let importResult = try await container.transactionImportPipeline.execute(
                    statement: statement,
                    target: target,
                    ledgerKind: ledgerKind,
                    context: context
                )
                importedCount += importResult.inserted
                CLIProgressReporter.report(
                    "[\(url.lastPathComponent)] imported: \(importResult.inserted), duplicates: \(importResult.skipped)"
                )
            } catch {
                CLIProgressReporter.error("[\(url.lastPathComponent)] \(error.localizedDescription)")
            }
        }

        guard !skipAnalysis, importedCount > 0 else { return }

        let transactions = try await container.transactionRepository.fetchTransactions()
        let defaults = IntelligenceServiceConfiguration.default
        let config = try IntelligenceServiceConfiguration(
            correctionStoreURL: defaults.correctionStoreURL,
            personalizedKNNModelURL: defaults.personalizedKNNModelURL,
            databaseQueue: DatabaseManager.shared.dbQueue
        )
        let service = await TransactionIntelligenceServiceImpl(configuration: config)
        let results = try await service.analyzeBatch(transactions, context: .empty)
        CLIProgressReporter.report("Categorized \(results.count) transactions")
    }
}
