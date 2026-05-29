import FinanceCore
import FinanceParsers
import Foundation
import Observation
import OSLog

let logger = FinanceLogger.importPipeline

@MainActor
@Observable
final class ImportViewModel {
    enum Step: Int, Equatable {
        case source = 0
        case upload = 1
        case review = 2
    }

    var currentStep: Step = .source
    var isDraggedOver: Bool = false

    let importSession: ImportSession
    let transactionImportPipeline: TransactionImportPipeline
    let bankRepository: any BankRepository
    let ledgerRepository: any LedgerRepository
    let transactionRepository: any TransactionRepository
    let categorizationScheduler: CategorizationScheduler?

    var ledgers: [Ledger] = []
    var banks: [Bank] = []
    var duplicateTransactionIndices: Set<Int> = [] // full skip set: within-batch dups + already-in-DB
    var alreadyInDBIndices: Set<Int> = [] // subset: only transactions already in DB
    var lastImportResult: ImportResult?
    var currentFileIndex: Int = 0
    var totalFilesToParse: Int = 0

    var accountMatcher: AccountMatcher

    var fileStatementPairs: [(url: URL, statement: ParsedStatement)] {
        zip(importSession.fileURLs, importSession.parsedStatements).map { ($0, $1) }
    }

    var supportedSources: [(bankName: String, sourceType: StatementSourceType)] {
        StatementSourceRegistry.supportedSources
    }

    /// For backward compatibility with views
    var fileURLs: [URL] {
        get { importSession.fileURLs }
        set { importSession.fileURLs = newValue }
    }

    var parsedStatements: [ParsedStatement] {
        get { importSession.parsedStatements }
        set { importSession.parsedStatements = newValue }
    }

    var selectedTarget: TransactionImportTarget? {
        get { importSession.selectedTarget }
        set { importSession.selectedTarget = newValue }
    }

    var selectedSource: StatementSource? {
        get { importSession.selectedSource }
        set { importSession.selectedSource = newValue }
    }

    var isLoading: Bool {
        get { importSession.isLoading }
        set { importSession.isLoading = newValue }
    }

    var errorMessage: String? {
        get { importSession.errorMessage }
        set { importSession.errorMessage = newValue }
    }

    var importResult: ImportResult? {
        get { importSession.importResult }
        set { importSession.importResult = newValue }
    }

    init(
        transactionImportPipeline: TransactionImportPipeline,
        bankRepository: any BankRepository,
        ledgerRepository: any LedgerRepository,
        transactionRepository: any TransactionRepository,
        initialTarget: TransactionImportTarget? = nil,
        categorizationScheduler: CategorizationScheduler? = nil
    ) {
        importSession = ImportSession()
        self.transactionImportPipeline = transactionImportPipeline
        self.bankRepository = bankRepository
        self.ledgerRepository = ledgerRepository
        self.transactionRepository = transactionRepository
        self.categorizationScheduler = categorizationScheduler
        accountMatcher = AccountMatcher(
            ledgerRepository: ledgerRepository,
            bankRepository: bankRepository
        )
        if let initialTarget {
            importSession.selectedTarget = initialTarget
        }
    }

    func setFileURLs(_ urls: [URL]) {
        logger.info("setFileURLs called with \(urls.count, privacy: .public) file(s)")
        importSession.fileURLs = urls
        importSession.errorMessage = nil
        logger.debug("fileURLs updated, errorMessage cleared")
    }

    func setSource(_ source: StatementSource?) {
        importSession.selectedSource = source
        importSession.fileURLs = []
        importSession.parsedStatements = []
        importSession.errorMessage = nil
        logger
            .info("Source changed to \(source?.displayName ?? "none", privacy: .public), cleared files and statements")
    }

    func parseFiles(_ urls: [URL]) {
        setFileURLs(urls)
        parseFiles()
    }

    func parseFiles() {
        logger.info("parseFiles() called, scheduling Task")
        Task {
            guard !importSession.fileURLs.isEmpty else {
                importSession.errorMessage = "No files selected"
                return
            }

            importSession.isLoading = true
            importSession.errorMessage = nil
            totalFilesToParse = importSession.fileURLs.count
            currentFileIndex = 0
            var statements: [ParsedStatement] = []
            let parser = ImportFileParser()

            for fileURL in importSession.fileURLs {
                do {
                    let statement = try await parser.parse(fileURL: fileURL)
                    statements.append(statement)
                    currentFileIndex += 1
                } catch let error as FinanceCore.TransactionImportError {
                    importSession.errorMessage = "Error parsing \(fileURL.lastPathComponent): \(error.userMessage)"
                    importSession.parsedStatements = []
                    importSession.isLoading = false
                    currentFileIndex = 0
                    totalFilesToParse = 0
                    return
                } catch {
                    let fileName = fileURL.lastPathComponent
                    let errorDesc = error.localizedDescription
                    importSession.errorMessage = "Error parsing \(fileName): \(errorDesc)"
                    importSession.parsedStatements = []
                    importSession.isLoading = false
                    currentFileIndex = 0
                    totalFilesToParse = 0
                    return
                }
            }

            importSession.parsedStatements = statements
            await loadTargetsOnAppear()
            await detectDuplicates(for: nil)
            await autoSelectMatchingTarget()
            currentStep = .review
            importSession.isLoading = false
            currentFileIndex = 0
            totalFilesToParse = 0
        }
    }

    func importTransactions() {
        Task {
            guard !importSession.fileURLs.isEmpty,
                  !importSession.parsedStatements.isEmpty,
                  let target = importSession.selectedTarget
            else {
                importSession.errorMessage = "Invalid import state"
                let filesOk = !importSession.fileURLs.isEmpty
                let stmtsOk = !importSession.parsedStatements.isEmpty
                let state = "files=\(filesOk), stmts=\(stmtsOk), target=\(importSession.selectedTarget != nil)"
                logger.error("Invalid state: \(state)")
                return
            }

            importSession.isLoading = true
            importSession.errorMessage = nil
            importSession.importResult = nil

            let fileCount = importSession.fileURLs.count
            let targetDesc = String(describing: target)
            logger.info(
                "Starting: \(fileCount, privacy: .public) files, target: \(targetDesc, privacy: .public)"
            )

            do {
                let result = try await performImport(target: target, fileCount: fileCount)
                importSession.importResult = result
                lastImportResult = result
                resetToSource()
                importSession.isLoading = false
                if let scheduler = categorizationScheduler {
                    Task.detached(priority: .background) {
                        await scheduler.run()
                    }
                }
                Task {
                    try? await Task.sleep(for: .seconds(4))
                    lastImportResult = nil
                }
            } catch {
                let desc = error.localizedDescription
                logger.error("Import failed: \(desc, privacy: .public)")
                importSession.errorMessage = "Import failed: \(desc)"
                importSession.isLoading = false
            }
        }
    }
}
