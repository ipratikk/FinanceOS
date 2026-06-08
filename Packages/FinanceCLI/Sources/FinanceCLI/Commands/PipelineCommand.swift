import ArgumentParser
import FinanceCore
import FinanceIntelligence
import FinanceParsers
import Foundation

@available(macOS 10.15, *)
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

    @Flag(name: .long, help: "Auto-create ledgers for unrecognized bank/card combinations")
    var autoCreateLedgers: Bool = false

    func run() async throws {
        if let dbPath {
            DatabaseManager.configure(url: URL(fileURLWithPath: dbPath))
        }
        let container = await AppContainer.shared
        var ledgers = try await container.ledgerRepository.fetchLedgers()
        let banks = try await container.bankRepository.fetchBanks()
        let importedCount = try await importStatements(container: container, ledgers: &ledgers, banks: banks)
        guard !skipAnalysis, importedCount > 0 else {
            if importedCount == 0 {
                CLIProgressReporter.report("No new transactions imported — skipping analysis")
            }
            return
        }
        try await runAnalysis(container: container)
    }

    private func importStatements(
        container: AppContainer,
        ledgers: inout [Ledger],
        banks: [Bank]
    ) async throws -> Int {
        var importedCount = 0
        for path in filePaths {
            let url = URL(fileURLWithPath: path)
            do {
                let source = try StatementDetector.detect(fileURL: url)
                let statement = try UnifiedStatementParser().parse(fileURL: url, detectedSource: source).statement
                var target = ImportTargetMatcher.bestTarget(for: statement, ledgers: ledgers, banks: banks)
                if target == nil, autoCreateLedgers {
                    target = try await autoCreate(
                        for: statement, source: source,
                        banks: banks, ledgerRepository: container.ledgerRepository, ledgers: &ledgers
                    )
                }
                guard let resolvedTarget = target else {
                    CLIProgressReporter.error("[\(url.lastPathComponent)] no matching ledger — skipping")
                    continue
                }
                let kind: LedgerKind = source.sourceType == .creditCard ? .creditCard : .bankAccount
                let result = try await container.transactionImportPipeline.execute(
                    statement: statement, target: resolvedTarget,
                    ledgerKind: kind, context: OperationContext(name: "cli-pipeline")
                )
                importedCount += result.inserted
                CLIProgressReporter.report(
                    "[\(url.lastPathComponent)] imported: \(result.inserted), duplicates: \(result.skipped)"
                )
            } catch {
                CLIProgressReporter.error("[\(url.lastPathComponent)] \(error.localizedDescription)")
            }
        }
        return importedCount
    }

    private func runAnalysis(container: AppContainer) async throws {
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
        printCategorySummary(results)
    }

    private func autoCreate(
        for statement: ParsedStatement,
        source: StatementSource,
        banks: [Bank],
        ledgerRepository: any LedgerRepository,
        ledgers: inout [Ledger]
    ) async throws -> TransactionImportTarget? {
        guard let bank = banks.first(where: { ImportTargetMatcher.fuzzyMatch($0.name, statement.bankName) }) else {
            CLIProgressReporter.error("Unknown bank '\(statement.bankName)' — cannot auto-create ledger")
            return nil
        }
        let kind: LedgerKind = source.sourceType == .creditCard ? .creditCard : .bankAccount
        let last4 = statement.cardLast4 ?? statement.accountLast4 ?? ""
        if let existing = ledgers.first(where: {
            $0.bankId == bank.id && $0.kind == kind
                && ($0.last4 == last4 || last4.isEmpty || $0.last4.isEmpty)
        }) {
            return .ledger(existing.id)
        }
        let displayName = last4.isEmpty ? statement.bankName : "\(statement.bankName) ••\(last4)"
        let ledger = Ledger(bankId: bank.id, kind: kind, displayName: displayName, last4: last4)
        try await ledgerRepository.insert(ledger)
        ledgers.append(ledger)
        CLIProgressReporter.report("Created ledger '\(displayName)' (\(kind.rawValue))")
        return .ledger(ledger.id)
    }

    private func printCategorySummary(_ results: [AnalyzedTransaction]) {
        let groups = Dictionary(grouping: results, by: { $0.categoryPrediction.categoryId })
        CLIProgressReporter.report("─── Category breakdown (spend / income) ───")
        for (cat, txns) in groups.sorted(by: { $0.value.count > $1.value.count }) {
            CLIProgressReporter.report(categoryLine(cat: cat, txns: txns))
        }
        let uncategorized = results.count(where: { $0.categoryPrediction.categoryId == "uncategorized" })
        let pct = results.isEmpty ? 0.0 : Double(uncategorized) / Double(results.count) * 100
        let summary = String(format: "Uncategorized: %d / %d  (%.1f%%)", uncategorized, results.count, pct)
        CLIProgressReporter.report(summary)
    }

    private func categoryLine(cat: String, txns: [AnalyzedTransaction]) -> String {
        let spend = txns.filter { $0.transaction.transactionType == .debit }
            .reduce(Decimal(0)) { $0 + Decimal($1.transaction.amountMinorUnits) / 100 }
        let income = txns.filter { $0.transaction.transactionType == .credit }
            .reduce(Decimal(0)) { $0 + Decimal($1.transaction.amountMinorUnits) / 100 }
        let spendD = (spend as NSDecimalNumber).doubleValue
        let incomeD = (income as NSDecimalNumber).doubleValue
        let catPad = cat.padding(toLength: 22, withPad: " ", startingAt: 0)
        if incomeD > 0, spendD > 0 {
            return String(format: "  %@ %3d txns  out %10.2f  in %10.2f", catPad, txns.count, spendD, incomeD)
        } else if incomeD > 0 {
            return String(format: "  %@ %3d txns  in  %10.2f", catPad, txns.count, incomeD)
        } else {
            return String(format: "  %@ %3d txns  out %10.2f", catPad, txns.count, spendD)
        }
    }
}
