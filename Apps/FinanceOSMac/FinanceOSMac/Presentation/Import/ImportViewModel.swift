import FinanceCore
import FinanceParsers
import Foundation
import Observation
import OSLog

let logger = FinanceLogger.importPipeline

@MainActor
@Observable
final class ImportViewModel {
    let importSession: ImportSession
    let transactionImportPipeline: TransactionImportPipeline
    let bankRepository: any BankRepository
    let ledgerRepository: any LedgerRepository
    let transactionRepository: any TransactionRepository

    var ledgers: [Ledger] = []
    var banks: [Bank] = []
    var duplicateTransactionIndices: Set<Int> = []

    private lazy var accountMatcher = AccountMatcher(
        ledgerRepository: ledgerRepository,
        bankRepository: bankRepository
    )

    var fileStatementPairs: [(url: URL, statement: ParsedStatement)] {
        zip(importSession.fileURLs, importSession.parsedStatements).map { ($0, $1) }
    }

    var supportedSources: [(bankName: String, sourceType: StatementSourceType)] {
        StatementSourceRegistry.supportedSources
    }

    // For backward compatibility with views
    var fileURLs: [URL] {
        importSession.fileURLs
    }

    var parsedStatements: [ParsedStatement] {
        importSession.parsedStatements
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
        transactionRepository: any TransactionRepository
    ) {
        self.importSession = ImportSession()
        self.transactionImportPipeline = transactionImportPipeline
        self.bankRepository = bankRepository
        self.ledgerRepository = ledgerRepository
        self.transactionRepository = transactionRepository
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

    func parseFiles() {
        logger.info("parseFiles() called, scheduling Task")
        Task {
            guard !importSession.fileURLs.isEmpty else {
                importSession.errorMessage = "No files selected"
                return
            }

            importSession.isLoading = true
            importSession.errorMessage = nil
            var statements: [ParsedStatement] = []

            for fileURL in importSession.fileURLs {
                do {
                    let statement = try await parseFile(fileURL)
                    statements.append(statement)
                } catch let error as FinanceCore.TransactionImportError {
                    importSession.errorMessage = "Error parsing \(fileURL.lastPathComponent): \(error.userMessage)"
                    importSession.parsedStatements = []
                    importSession.isLoading = false
                    return
                } catch {
                    importSession.errorMessage = "Error parsing \(fileURL.lastPathComponent): \(error.localizedDescription)"
                    importSession.parsedStatements = []
                    importSession.isLoading = false
                    return
                }
            }

            importSession.parsedStatements = statements
            await loadTargetsOnAppear()
            await autoSelectMatchingTarget()
            importSession.isLoading = false
        }
    }

    private func parseFile(_ fileURL: URL) async throws -> ParsedStatement {
        let fileName = fileURL.lastPathComponent

        do {
            let detectedSource = try StatementDetector.detect(fileURL: fileURL)
            let result = try UnifiedStatementParser().parse(fileURL: fileURL, detectedSource: detectedSource)
            let txnCount = result.statement.transactions.count
            logger.logInfo(
                "Parsed {file}: {count} txns from {bank}",
                ["file": fileName, "count": txnCount, "bank": detectedSource.bankName]
            )
            return result.statement
        } catch let error as DetectionError {
            throw TransactionImportError.unsupportedFormat(error.description)
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
                reset()
                importSession.isLoading = false
            } catch {
                let desc = error.localizedDescription
                logger.error("Import failed: \(desc, privacy: .public)")
                importSession.errorMessage = "Import failed: \(desc)"
                importSession.isLoading = false
            }
        }
    }

    private func reset() {
        importSession.reset()
    }
}
