import ArgumentParser
import FinanceCore
import FinanceIntelligence
import Foundation
import GRDB

@available(macOS 10.15, *)
struct AnalyzeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "analyze",
        abstract: "Run intelligence enrichment on transactions in the database"
    )

    @Option(name: .long, help: "Override database path")
    var dbPath: String?

    @Flag(name: .long, help: "Show per-transaction descriptions (first 50)")
    var verbose: Bool = false

    func run() async throws {
        if let dbPath {
            DatabaseManager.configure(url: URL(fileURLWithPath: dbPath))
        }

        let dbQueue = DatabaseManager.shared.dbQueue
        let txnRepo = GRDBTransactionRepository(dbQueue: dbQueue)
        let transactions = try await txnRepo.fetchTransactions()

        guard !transactions.isEmpty else {
            CLIProgressReporter.report("No transactions found in database")
            return
        }

        let defaults = IntelligenceServiceConfiguration.default
        let config = try IntelligenceServiceConfiguration(
            correctionStoreURL: defaults.correctionStoreURL,
            personalizedKNNModelURL: defaults.personalizedKNNModelURL,
            databaseQueue: dbQueue,
            transactionRepository: txnRepo
        )
        let service = await TransactionIntelligenceServiceImpl(configuration: config)
        let enriched = try await service.enrichBatch(transactions)

        CLIProgressReporter.report("Enriched \(enriched.count) of \(transactions.count) transactions")

        if verbose {
            let header = "  " +
                "Description".padding(toLength: 40, withPad: " ", startingAt: 0) + " " +
                "Category".padding(toLength: 22, withPad: " ", startingAt: 0) + " " +
                "Human Description"
            CLIProgressReporter.report(header)
            for item in enriched.prefix(50) {
                let desc = String(item.transaction.description.prefix(40))
                    .padding(toLength: 40, withPad: " ", startingAt: 0)
                let cat = item.categoryPrediction.categoryId
                    .padding(toLength: 22, withPad: " ", startingAt: 0)
                let human = item.humanDescription ?? "(no description)"
                CLIProgressReporter.report("  \(desc) \(cat) \(human)")
            }
        }
    }
}
