@preconcurrency import Apollo
@preconcurrency import ApolloAPI
import FinanceCore
import FinanceOSAPI
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
    let graphQLClient: ApolloGraphQLClient
    let bankRepository: any BankRepository
    let ledgerRepository: any LedgerRepository
    let categorizationScheduler: CategorizationScheduler?
    let fileParser: any StatementParsingProtocol
    let duplicateDetector: any DuplicateDetectingProtocol

    var ledgers: [Ledger] = []
    var banks: [Bank] = []
    var duplicateTransactionIndices: Set<Int> = []
    var alreadyInDBIndices: Set<Int> = []
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
        graphQLClient: ApolloGraphQLClient,
        bankRepository: any BankRepository,
        ledgerRepository: any LedgerRepository,
        initialTarget: TransactionImportTarget? = nil,
        categorizationScheduler: CategorizationScheduler? = nil,
        fileParser: (any StatementParsingProtocol)? = nil,
        duplicateDetector: (any DuplicateDetectingProtocol)? = nil
    ) {
        importSession = ImportSession()
        self.graphQLClient = graphQLClient
        self.bankRepository = bankRepository
        self.ledgerRepository = ledgerRepository
        self.categorizationScheduler = categorizationScheduler
        self.fileParser = fileParser ?? ImportFileParser()
        self.duplicateDetector = duplicateDetector ?? ImportDuplicateDetector()
        accountMatcher = AccountMatcher(ledgerRepository: ledgerRepository, bankRepository: bankRepository)
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
            let parser = fileParser

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
                  let target = importSession.selectedTarget,
                  case let .ledger(ledgerId) = target
            else {
                importSession.errorMessage = "Select a ledger before importing"
                return
            }

            importSession.isLoading = true
            importSession.errorMessage = nil
            importSession.importResult = nil

            do {
                var totalInserted = 0
                var totalSkipped = 0

                for fileURL in importSession.fileURLs {
                    let fileData = try Data(contentsOf: fileURL)
                    let file = GraphQLFile(
                        fieldName: "file",
                        originalName: fileURL.lastPathComponent,
                        mimeType: "text/csv",
                        data: fileData
                    )
                    let mutation = UploadStatementMutation(ledgerId: ledgerId.uuidString, file: "")
                    let response = try await graphQLClient.upload(mutation: mutation, files: [file])
                    let result = response.uploadStatement
                    totalInserted += result.imported
                    totalSkipped += result.duplicates
                    logger.logInfo("File uploaded: {imported} imported, {dups} duplicates", [
                        "imported": result.imported,
                        "dups": result.duplicates
                    ])
                }

                let result = ImportResult(inserted: totalInserted, skipped: totalSkipped)
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
