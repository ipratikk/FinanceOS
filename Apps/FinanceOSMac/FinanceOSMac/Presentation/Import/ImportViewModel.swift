import FinanceCore
import FinanceParsers
import Foundation
import Observation
import OSLog

let logger = FinanceLogger.importPipeline

@MainActor
@Observable
final class ImportViewModel {
    var fileURLs: [URL] = []
    var parsedStatements: [ParsedStatement] = []
    var selectedTarget: TransactionImportTarget?
    var selectedSource: StatementSource?

    var isLoading = false
    var errorMessage: String?
    var importResult: ImportResult?

    var ledgers: [Ledger] = []
    var banks: [Bank] = []
    var duplicateTransactionIndices: Set<Int> = []

    var fileStatementPairs: [(url: URL, statement: ParsedStatement)] {
        zip(fileURLs, parsedStatements).map { ($0, $1) }
    }

    var supportedSources: [(bankName: String, sourceType: StatementSourceType)] {
        StatementSourceRegistry.supportedSources
    }

    let transactionImportPipeline: TransactionImportPipeline
    let bankRepository: any BankRepository
    let ledgerRepository: any LedgerRepository
    let transactionRepository: any TransactionRepository

    init(
        transactionImportPipeline: TransactionImportPipeline,
        bankRepository: any BankRepository,
        ledgerRepository: any LedgerRepository,
        transactionRepository: any TransactionRepository
    ) {
        self.transactionImportPipeline = transactionImportPipeline
        self.bankRepository = bankRepository
        self.ledgerRepository = ledgerRepository
        self.transactionRepository = transactionRepository
    }

    func setFileURLs(_ urls: [URL]) {
        logger.info("setFileURLs called with \(urls.count, privacy: .public) file(s)")
        fileURLs = urls
        errorMessage = nil
        logger.debug("fileURLs updated, errorMessage cleared")
    }

    func setSource(_ source: StatementSource?) {
        selectedSource = source
        fileURLs = []
        parsedStatements = []
        errorMessage = nil
        logger
            .info("Source changed to \(source?.displayName ?? "none", privacy: .public), cleared files and statements")
    }

    func parseFiles() {
        logger.info("parseFiles() called, scheduling Task")
        Task {
            guard !fileURLs.isEmpty else {
                errorMessage = "No files selected"
                return
            }

            isLoading = true
            errorMessage = nil
            var statements: [ParsedStatement] = []

            for fileURL in fileURLs {
                do {
                    let statement = try await parseFile(fileURL)
                    statements.append(statement)
                } catch let error as FinanceCore.TransactionImportError {
                    errorMessage = "Error parsing \(fileURL.lastPathComponent): \(error.userMessage)"
                    parsedStatements = []
                    isLoading = false
                    return
                } catch {
                    errorMessage = "Error parsing \(fileURL.lastPathComponent): \(error.localizedDescription)"
                    parsedStatements = []
                    isLoading = false
                    return
                }
            }

            self.parsedStatements = statements
            await loadTargetsOnAppear()
            await autoSelectMatchingTarget()
            isLoading = false
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
            guard !fileURLs.isEmpty,
                  !parsedStatements.isEmpty,
                  let target = selectedTarget
            else {
                errorMessage = "Invalid import state"
                let filesOk = !fileURLs.isEmpty
                let stmtsOk = !parsedStatements.isEmpty
                let state = "files=\(filesOk), stmts=\(stmtsOk), target=\(selectedTarget != nil)"
                logger.error("Invalid state: \(state)")
                return
            }

            isLoading = true
            errorMessage = nil
            importResult = nil

            let fileCount = self.fileURLs.count
            let targetDesc = String(describing: target)
            logger.info(
                "Starting: \(fileCount, privacy: .public) files, target: \(targetDesc, privacy: .public)"
            )

            do {
                let result = try await performImport(target: target, fileCount: fileCount)
                importResult = result
                reset()
                isLoading = false
            } catch {
                let desc = error.localizedDescription
                logger.error("Import failed: \(desc, privacy: .public)")
                errorMessage = "Import failed: \(desc)"
                isLoading = false
            }
        }
    }
}
