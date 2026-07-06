@preconcurrency import Apollo
@preconcurrency import ApolloAPI
import FinanceCore
import FinanceOSAPI
import Foundation
import Observation
import OSLog

let logger = FinanceLogger.importPipeline

@MainActor
@Observable
final class ImportViewModel {
    enum ImportPhase: Equatable {
        case idle
        case previewing
        case readyToImport
        case importing
    }

    var phase: ImportPhase = .idle
    var isDraggedOver: Bool = false

    let importSession: ImportSession
    let graphQLClient: ApolloGraphQLClient
    let fileParser: any StatementParsingProtocol

    var ledgers: [Ledger] = []
    var banks: [Bank] = []
    var lastImportResult: ImportResult?
    var currentFileIndex: Int = 0
    var totalFilesToParse: Int = 0
    var pendingPasswordRequest: PasswordPromptRequest?
    let passwordStore: any ImportPasswordStoring

    var fileStatementPairs: [(url: URL, statement: ParsedStatement)] {
        zip(importSession.fileURLs, importSession.parsedStatements).map { ($0, $1) }
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
        initialTarget: TransactionImportTarget? = nil,
        fileParser: (any StatementParsingProtocol)? = nil,
        passwordStore: (any ImportPasswordStoring)? = nil
    ) {
        importSession = ImportSession()
        self.graphQLClient = graphQLClient
        self.fileParser = fileParser ?? ImportFileParser(graphQLClient: graphQLClient)
        self.passwordStore = passwordStore ?? ImportPasswordStore()
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

            phase = .previewing
            importSession.isLoading = true
            importSession.errorMessage = nil
            totalFilesToParse = importSession.fileURLs.count
            currentFileIndex = 0
            var statements: [ParsedStatement] = []
            let parser = fileParser

            for fileURL in importSession.fileURLs {
                do {
                    let statement = try await parseWithPasswordRetry(fileURL: fileURL, parser: parser)
                    statements.append(statement)
                    currentFileIndex += 1
                } catch let error as FinanceCore.TransactionImportError {
                    importSession.errorMessage = "Error parsing \(fileURL.lastPathComponent): \(error.userMessage)"
                    importSession.parsedStatements = []
                    importSession.isLoading = false
                    currentFileIndex = 0
                    totalFilesToParse = 0
                    phase = .idle
                    return
                } catch {
                    let fileName = fileURL.lastPathComponent
                    let errorDesc = error.localizedDescription
                    importSession.errorMessage = "Error parsing \(fileName): \(errorDesc)"
                    importSession.parsedStatements = []
                    importSession.isLoading = false
                    currentFileIndex = 0
                    totalFilesToParse = 0
                    phase = .idle
                    return
                }
            }

            importSession.parsedStatements = statements
            await loadTargetsOnAppear()
            await autoSelectMatchingTarget()
            flushPendingKeychainSaves()
            phase = .readyToImport
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
            flushPendingKeychainSaves()
            phase = .importing
            importSession.isLoading = true
            importSession.errorMessage = nil
            importSession.importResult = nil
            do {
                let (inserted, skipped) = try await uploadFiles(ledgerId: ledgerId)
                let result = ImportResult(inserted: inserted, skipped: skipped)
                importSession.importResult = result
                lastImportResult = result
                resetToIdle()
                importSession.isLoading = false
                Task {
                    try? await Task.sleep(for: .seconds(4))
                    lastImportResult = nil
                }
            } catch {
                let desc = error.localizedDescription
                logger.error("Import failed: \(desc, privacy: .public)")
                importSession.errorMessage = "Import failed: \(desc)"
                importSession.isLoading = false
                phase = .readyToImport
            }
        }
    }

    private func uploadFiles(ledgerId: UUID) async throws -> (inserted: Int, skipped: Int) {
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
            let password = importSession.filePasswords[fileURL]
            let sealedPassword = try password.map { try ImportPasswordCrypto.seal($0) }
            let mutation = UploadStatementMutation(
                ledgerId: ledgerId.uuidString,
                file: "",
                password: sealedPassword.map {
                    .some(EncryptedPassword(ephemeralPublicKey: $0.ephemeralPublicKey, ciphertext: $0.ciphertext))
                } ?? .null
            )
            let response = try await graphQLClient.upload(mutation: mutation, files: [file])
            let result = response.uploadStatement
            totalInserted += result.imported
            totalSkipped += result.duplicates
            logger.logInfo("File uploaded: {imported} imported, {dups} duplicates", [
                "imported": result.imported,
                "dups": result.duplicates
            ])
        }
        return (totalInserted, totalSkipped)
    }
}
