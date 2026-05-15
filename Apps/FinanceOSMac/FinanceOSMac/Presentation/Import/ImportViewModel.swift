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

    var accounts: [Account] = []
    var cards: [Card] = []
    var banks: [Bank] = []
    var duplicateTransactionIndices: Set<Int> = []

    var fileStatementPairs: [(url: URL, statement: ParsedStatement)] {
        zip(fileURLs, parsedStatements).map { ($0, $1) }
    }

    var supportedSources: [(bankName: String, sourceType: StatementSourceType)] {
        parserRegistry.supportedSources
    }

    let transactionImporter: any TransactionImporting
    let transactionImportPipeline: TransactionImportPipeline
    let bankRepository: any BankRepository
    let accountRepository: any AccountRepository
    let cardRepository: any CardRepository
    let transactionRepository: any TransactionRepository
    let parserRegistry: FinanceCore.StatementParserRegistry

    init(
        transactionImporter: any TransactionImporting,
        transactionImportPipeline: TransactionImportPipeline,
        bankRepository: any BankRepository,
        accountRepository: any AccountRepository,
        cardRepository: any CardRepository,
        transactionRepository: any TransactionRepository,
        parserRegistry: FinanceCore.StatementParserRegistry
    ) {
        self.transactionImporter = transactionImporter
        self.transactionImportPipeline = transactionImportPipeline
        self.bankRepository = bankRepository
        self.accountRepository = accountRepository
        self.cardRepository = cardRepository
        self.transactionRepository = transactionRepository
        self.parserRegistry = parserRegistry
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
        let format = StatementFileFormat.detect(from: fileURL)
        let fileName = fileURL.lastPathComponent

        guard let source = selectedSource, [.csv, .txt].contains(format) else {
            throw TransactionImportError.unsupportedFormat(format.rawValue)
        }

        guard let parser = parserRegistry.parser(for: source) else {
            throw TransactionImportError.unsupportedFormat("\(source.displayName) - \(format.rawValue)")
        }

        let rows = try CSVRowReader.read(from: fileURL)
        let statement = try parser.parse(rows: rows)

        logger.info("Parsed \(fileName, privacy: .public): \(statement.transactions.count, privacy: .public) txns")
        return statement
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
