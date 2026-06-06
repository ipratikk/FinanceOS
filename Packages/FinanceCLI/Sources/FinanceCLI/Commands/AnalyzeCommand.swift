import ArgumentParser
import FinanceCore
import FinanceIntelligence
import Foundation

struct AnalyzeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "analyze",
        abstract: "Run intelligence categorization on transactions in the database"
    )

    @Option(name: .long, help: "Override database path")
    var dbPath: String?

    func run() async throws {
        if let dbPath {
            DatabaseManager.configure(url: URL(fileURLWithPath: dbPath))
        }

        let container = await AppContainer.shared
        let transactions = try await container.transactionRepository.fetchTransactions()

        guard !transactions.isEmpty else {
            CLIProgressReporter.report("No transactions found in database")
            return
        }

        let defaults = IntelligenceServiceConfiguration.default
        let config = try IntelligenceServiceConfiguration(
            correctionStoreURL: defaults.correctionStoreURL,
            personalizedKNNModelURL: defaults.personalizedKNNModelURL,
            databaseQueue: DatabaseManager.shared.dbQueue
        )
        let service = await TransactionIntelligenceServiceImpl(configuration: config)
        let results = try await service.analyzeBatch(transactions, context: .empty)
        CLIProgressReporter.report("Categorized \(results.count) of \(transactions.count) transactions")
    }
}
