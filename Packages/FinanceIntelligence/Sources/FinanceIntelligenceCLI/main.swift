import ArgumentParser
import FinanceCore
import FinanceIntelligence
import Foundation
import GRDB

@main
struct FinanceIntelligenceCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "intelligence",
        abstract: "Run transaction intelligence pipeline against a FinanceOS SQLite database.",
        subcommands: [EvalCommand.self, SampleCommand.self, ExportCommand.self, TrainCommand.self],
        defaultSubcommand: EvalCommand.self
    )
}

// MARK: - eval

struct EvalCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "eval",
        abstract: "Analyze transactions from a SQLite DB and print predictions."
    )

    @Option(name: .long, help: "Path to FinanceOS SQLite database file.")
    var db: String

    @Option(name: .long, help: "Max transactions to analyze (0 = all).")
    var limit: Int = 0

    @Flag(name: .long, help: "Show full debug info including features.")
    var verbose: Bool = false

    mutating func run() async throws {
        let dbQueue = try openDB(path: db)
        let transactions = try await fetchTransactions(from: dbQueue, limit: limit)
        print("Loaded \(transactions.count) transactions from \(db)\n")

        let service = await TransactionIntelligenceServiceImpl()
        let results = try await service.analyzeBatch(transactions, context: .empty)

        printReport(results, verbose: verbose)

        let insights = try await service.generateInsights(for: transactions)
        if !insights.isEmpty {
            printInsights(insights)
        }
    }
}

// MARK: - sample

struct SampleCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sample",
        abstract: "Run intelligence on built-in sample descriptions (no DB needed)."
    )

    mutating func run() async throws {
        let samples = sampleDescriptions()
        let normalizer = MerchantNormalizer()
        let categorizer = RuleBasedCategorizer()
        let extractor = TransactionFeatureExtractor()
        let width = 45
        print(String(repeating: "─", count: 110))
        print(padRight("Raw Description", width) + padRight("Merchant", 25) + padRight("Category", 20) + "Conf  Source")
        print(String(repeating: "─", count: 110))
        for raw in samples {
            printSampleRow(
                raw: raw,
                normalizer: normalizer,
                categorizer: categorizer,
                extractor: extractor,
                width: width
            )
        }
        print(String(repeating: "─", count: 110))
    }
}

private func sampleDescriptions() -> [String] {
    [
        "SQ *BLUE BOTTLE 000123 SAN FRANCISCO CA",
        "UBER TRIP HELP.UBER.COM",
        "AMZN MKTP US*8A2K91",
        "TST* SWEETGREEN #1042",
        "SPOTIFY AB STOCKHOLM",
        "NETFLIX.COM",
        "SALARY CREDIT JUNE 2026",
        "NEFT TO JOHN DOE REF 20260601",
        "ATM WITHDRAWAL HDFC BANK 12345",
        "ZOMATO FOOD ORDER",
        "SWIGGY ORDER 123456",
        "AIRTEL POSTPAID BILL",
        "STARBUCKS STORE 12345 MUMBAI MH",
        "REFUND FROM AMAZON ORDER 456789",
        "HDFC BANK ANNUAL FEE"
    ]
}

private func printSampleRow(
    raw: String,
    normalizer: MerchantNormalizer,
    categorizer: RuleBasedCategorizer,
    extractor: TransactionFeatureExtractor,
    width: Int
) {
    let txn = Transaction(
        postedAt: Date(), description: raw,
        amountMinorUnits: 10000, currencyCode: "INR",
        transactionType: .debit
    )
    let features = extractor.extract(from: txn)
    let merchant = normalizer.normalize(raw)
    let rulePred = categorizer.categorize(features)
    let categoryId: String
    let confidence: Double
    let source: String
    if let aliasId = merchant.categoryId {
        categoryId = aliasId.components(separatedBy: ".").first ?? aliasId
        confidence = merchant.confidence
        source = "alias"
    } else {
        categoryId = rulePred.categoryId
        confidence = rulePred.confidence
        source = rulePred.source.rawValue
    }
    print(
        padRight(raw, width) +
            padRight(merchant.canonicalName, 25) +
            padRight(categoryId, 20) +
            String(format: "%.2f  ", confidence) +
            source
    )
}

// MARK: - Report Printing

private func printReport(_ results: [AnalyzedTransaction], verbose: Bool) {
    let width = 40
    print(String(repeating: "─", count: 115))
    print(
        padRight("Description", width) +
            padRight("Merchant", 25) +
            padRight("Category", 22) +
            padRight("Conf", 6) +
            "Source"
    )
    print(String(repeating: "─", count: 115))

    for result in results {
        let pred = result.categoryPrediction
        let merch = result.merchantCandidate
        let correctedMark = result.isUserCorrected ? " ✓" : ""
        print(
            padRight(result.transaction.description, width) +
                padRight(merch.canonicalName + correctedMark, 25) +
                padRight(pred.categoryId, 22) +
                padRight(String(format: "%.2f", pred.confidence), 6) +
                pred.source.rawValue
        )
        if verbose {
            print("  tokens: \(result.features.tokens.prefix(8).joined(separator: ", "))")
        }
    }
    print(String(repeating: "─", count: 115))

    let categoryGroups = Dictionary(grouping: results, by: { $0.categoryPrediction.categoryId })
    print("\nCategory breakdown:")
    for (cat, txns) in categoryGroups.sorted(by: { $0.value.count > $1.value.count }) {
        let total = txns.reduce(0) { $0 + $1.transaction.amountMinorUnits }
        let amount = String(format: "%10.2f", Double(total) / 100)
        print("  \(padRight(cat, 22)) \(String(format: "%3d", txns.count)) txns   \(amount)")
    }

    let uncategorized = results.count(where: { $0.categoryPrediction.categoryId == "uncategorized" })
    let pct = results.isEmpty ? 0 : Double(uncategorized) / Double(results.count) * 100
    print(String(format: "\nUncategorized: %d / %d  (%.1f%%)", uncategorized, results.count, pct))

    let corrected = results.filter(\.isUserCorrected).count
    if corrected > 0 { print("User-corrected: \(corrected)") }
}

private func printInsights(_ insights: [TransactionInsight]) {
    print("\n─── Insights ──────────────────────────────────")
    for insight in insights {
        let icon: String = switch insight.severity {
        case .info: "ℹ"
        case .warning: "⚠"
        case .alert: "🚨"
        }
        print("\(icon)  [\(insight.kind.rawValue)]  \(insight.title)")
        print("   \(insight.explanation)")
        print(String(
            format: "   Confidence: %.0f%%  |  Affects %d txns",
            insight.confidence * 100,
            insight.affectedTransactionIDs.count
        ))
    }
}

private func padRight(_ s: String, _ width: Int) -> String {
    s.count >= width ? String(s.prefix(width - 1)) + " " : s + String(repeating: " ", count: width - s.count)
}

// MARK: - DB Helpers

private func openDB(path: String) throws -> DatabaseQueue {
    // Open existing app database — app has already run migrations.
    try DatabaseQueue(path: path)
}

private func fetchTransactions(from dbQueue: DatabaseQueue, limit: Int) async throws -> [Transaction] {
    let all = try await dbQueue.read { db in try Transaction.fetchAll(db) }
    let sorted = all.sorted { $0.postedAt > $1.postedAt }
    return limit > 0 ? Array(sorted.prefix(limit)) : sorted
}

// MARK: - train

struct TrainCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "train",
        abstract: "Train LocalTransactionLearner from CSV transactions (for reference only)."
    )

    @Argument(help: "Path to training CSV")
    var dataPath: String

    @Option(help: "Output directory")
    var output: String = "models/"

    mutating func run() async throws {
        print("Training CLI stub. Use CreateML for actual model training.")
        print("Data: \(dataPath)")
    }
}

// MARK: - export

struct ExportCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "export",
        abstract: "Export user corrections from corrections.json to a training-ready CSV."
    )

    @Option(name: .long, help: "Path to corrections.json (default: app support dir).")
    var corrections: String?

    @Option(name: .long, help: "Output CSV path.")
    var output: String = "corrections_export.csv"

    @Option(name: .long, help: "Path to SQLite DB (needed to resolve raw descriptions).")
    var db: String?

    mutating func run() async throws {
        let corrURL = resolveCorrectionsURL(path: corrections)
        guard FileManager.default.fileExists(atPath: corrURL.path) else {
            print("No corrections.json found at \(corrURL.path)")
            print("Make corrections in the app first, then re-run.")
            return
        }
        let store = UserCorrectionStore(storageURL: corrURL)
        let eligible = await store.exportTrainingEligible()
        guard !eligible.isEmpty else {
            print("No training-eligible corrections found.")
            return
        }
        let txnDescriptions = try await loadDescriptions(dbPath: db)
        let csv = buildCSV(from: eligible, txnDescriptions: txnDescriptions)
        try csv.write(to: URL(fileURLWithPath: output), atomically: true, encoding: .utf8)
        print("Exported \(eligible.count) corrections → \(output)")
    }

    private func resolveCorrectionsURL(path: String?) -> URL {
        if let path { return URL(fileURLWithPath: path) }
        let dirs = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let base = dirs.first ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("FinanceIntelligence").appendingPathComponent("corrections.json")
    }

    private func loadDescriptions(dbPath: String?) async throws -> [UUID: String] {
        guard let dbPath else { return [:] }
        let dbQueue = try openDB(path: dbPath)
        let txns = try await fetchTransactions(from: dbQueue, limit: 0)
        return Dictionary(uniqueKeysWithValues: txns.map { ($0.id, $0.description) })
    }

    private func buildCSV(from eligible: [UserCorrection], txnDescriptions: [UUID: String]) -> String {
        let header = "id,date,raw_description,user_category,corrected_merchant," +
            "original_category,original_confidence,model_version,source"
        let formatter = ISO8601DateFormatter()
        let rows = eligible.map { c -> String in
            let raw = (txnDescriptions[c.transactionId] ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let merchant = (c.correctedMerchant ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            return [
                c.id.uuidString,
                formatter.string(from: c.timestamp),
                "\"\(raw)\"",
                c.correctedCategory,
                "\"\(merchant)\"",
                c.originalCategory ?? "",
                c.originalConfidence.map { String(format: "%.3f", $0) } ?? "",
                c.modelVersion ?? "",
                "user_correction"
            ].joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }
}
