import FinanceCore
import Foundation
import Observation
import OSLog

private let logger = FinanceLogger.importPipeline

@MainActor
@Observable
final class ImportViewModel {
    var fileURLs: [URL] = []
    var parsedStatements: [ParsedStatement] = []
    var selectedTarget: TransactionImportTarget?

    var isLoading = false
    var errorMessage: String?
    var importResult: ImportResult?

    var accounts: [Account] = []
    var cards: [Card] = []
    var institutions: [Institution] = []
    var duplicateTransactionIndices: Set<Int> = []

    var fileStatementPairs: [(url: URL, statement: ParsedStatement)] {
        zip(fileURLs, parsedStatements).map { ($0, $1) }
    }

    var supportedSources: [(institution: String, sourceType: StatementSourceType)] {
        parserRegistry.supportedSources
    }

    private let transactionImporter: any TransactionImporting
    private let transactionImportPipeline: TransactionImportPipeline
    private let institutionRepository: any InstitutionRepository
    private let accountRepository: any AccountRepository
    private let cardRepository: any CardRepository
    private let transactionRepository: any TransactionRepository
    private let parserRegistry: StatementParserRegistry

    init(
        transactionImporter: any TransactionImporting,
        transactionImportPipeline: TransactionImportPipeline,
        institutionRepository: any InstitutionRepository,
        accountRepository: any AccountRepository,
        cardRepository: any CardRepository,
        transactionRepository: any TransactionRepository,
        parserRegistry: StatementParserRegistry
    ) {
        self.transactionImporter = transactionImporter
        self.transactionImportPipeline = transactionImportPipeline
        self.institutionRepository = institutionRepository
        self.accountRepository = accountRepository
        self.cardRepository = cardRepository
        self.transactionRepository = transactionRepository
        self.parserRegistry = parserRegistry
    }

    func setFileURLs(_ urls: [URL]) {
        fileURLs = urls
        errorMessage = nil
    }

    func parseFiles() {
        Task {
            guard !fileURLs.isEmpty else {
                errorMessage = "No files selected"
                logger.error("No file URLs provided")
                return
            }

            isLoading = true
            errorMessage = nil

            let fileCount = fileURLs.count
            logger.info("Starting parse of \(fileCount, privacy: .public) file(s)")

            var statements: [ParsedStatement] = []

            for fileURL in fileURLs {
                do {
                    let format = fileFormat(for: fileURL)
                    let fileName = fileURL.lastPathComponent
                    logger.debug("Parsing \(fileName, privacy: .public) as \(format.rawValue, privacy: .public)")

                    let statement = try await transactionImporter.parseStatement(
                        from: fileURL,
                        format: format
                    )

                    let txnCount = statement.transactions.count
                    logger.info("Parsed \(fileName, privacy: .public): \(txnCount, privacy: .public) txns")

                    statements.append(statement)
                } catch let error as TransactionImportError {
                    let fileName = fileURL.lastPathComponent
                    let formattedError = formatError(error)
                    logger.error("Parse error for \(fileName, privacy: .public): \(formattedError, privacy: .public)")
                    errorMessage = "Error parsing \(fileName): \(formattedError)"
                    parsedStatements = []
                    isLoading = false
                    return
                } catch {
                    let fileName = fileURL.lastPathComponent
                    let desc = error.localizedDescription
                    logger.error("Parse error for \(fileName, privacy: .public): \(desc, privacy: .public)")
                    errorMessage = "Error parsing \(fileName): \(error.localizedDescription)"
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

    func importTransactions() {
        Task {
            guard !fileURLs.isEmpty,
                  !parsedStatements.isEmpty,
                  let target = selectedTarget
            else {
                errorMessage = "Invalid import state"
                let filesOK = !self.fileURLs.isEmpty
                let statementsOK = !self.parsedStatements.isEmpty
                let targetOK = self.selectedTarget != nil
                let msg = "Invalid state: fileURLs=\(filesOK), stmts=\(statementsOK), target=\(targetOK)"
                logger.error("\(msg)")
                return
            }

            isLoading = true
            errorMessage = nil
            importResult = nil

            let fileCount = self.fileURLs.count
            let targetDesc = String(describing: target)
            logger.info("Starting: \(fileCount, privacy: .public) files, target: \(targetDesc, privacy: .public)")

            do {
                var totalInserted = 0
                var totalSkipped = 0

                for (index, fileURL) in fileURLs.enumerated() {
                    let format = fileFormat(for: fileURL)
                    let fileName = fileURL.lastPathComponent
                    let fileNumber = index + 1

                    logger.debug("Importing file \(fileNumber)/\(fileCount): \(fileName, privacy: .public)")

                    let result = try await transactionImportPipeline.execute(
                        fileURL: fileURL,
                        format: format,
                        target: target
                    )

                    totalInserted += result.inserted
                    totalSkipped += result.skipped

                    logger
                        .info(
                            "File \(fileName, privacy: .public): \(result.inserted, privacy: .public) inserted, \(result.skipped, privacy: .public) skipped"
                        )
                }

                importResult = ImportResult(inserted: totalInserted, skipped: totalSkipped)
                logger
                    .info(
                        "Import complete: \(totalInserted, privacy: .public) inserted, \(totalSkipped, privacy: .public) skipped"
                    )
                reset()
                isLoading = false
            } catch {
                logger.error("Import failed: \(error.localizedDescription, privacy: .public)")
                errorMessage = "Import failed: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    func loadTargetsOnAppear() async {
        do {
            logger.debug("Loading accounts, cards, and institutions")
            accounts = try await accountRepository.fetchAccounts()
            cards = try await cardRepository.fetchCards()
            institutions = try await institutionRepository.fetchInstitutions()
            let accountCount = accounts.count
            let cardCount = cards.count
            let institutionCount = institutions.count
            logger
                .debug(
                    "Loaded \(accountCount, privacy: .public) accounts, \(cardCount, privacy: .public) cards, and \(institutionCount, privacy: .public) institutions"
                )
        } catch {
            let errorMsg = error.localizedDescription
            logger.error("Failed to load targets: \(errorMsg, privacy: .public)")
            errorMessage = errorMsg
        }
    }

    private func autoSelectMatchingTarget() async {
        guard let statement = parsedStatements.first else { return }

        let isCard = statement.cardLast4 != nil
        let institutionName = statement.institution

        let matchingInstitution = institutions.first { inst in
            fuzzyMatch(inst.name, institutionName)
        }
        guard let institution = matchingInstitution else { return }

        if isCard {
            if let matchingCard = cards.first(where: { $0.institutionID == institution.id }) {
                selectedTarget = .card(matchingCard.id)
                logger.info("Auto-selected card: \(matchingCard.name, privacy: .public)")
                await detectDuplicates(for: .card(matchingCard.id))
            }
        } else {
            if let matchingAccount = accounts.first(where: { $0.institutionID == institution.id }) {
                selectedTarget = .account(matchingAccount.id)
                logger.info("Auto-selected account: \(matchingAccount.name, privacy: .public)")
                await detectDuplicates(for: .account(matchingAccount.id))
            }
        }
    }

    private func detectDuplicates(for target: TransactionImportTarget) async {
        do {
            let existingTransactions: [Transaction] = switch target {
            case let .account(id):
                try await transactionRepository.fetchTransactionsForAccount(id)
            case let .card(id):
                try await transactionRepository.fetchTransactionsForCard(id)
            }

            duplicateTransactionIndices = []

            for (index, statement) in parsedStatements.enumerated() {
                for (txnIndex, parsedTxn) in statement.transactions.enumerated() {
                    for existingTxn in existingTransactions {
                        if isSameTransaction(parsed: parsedTxn, existing: existingTxn) {
                            let flatIndex = parsedStatements[..<index]
                                .reduce(0) { $0 + $1.transactions.count } + txnIndex
                            duplicateTransactionIndices.insert(flatIndex)
                        }
                    }
                }
            }

            let dupCount = duplicateTransactionIndices.count
            logger.info("Found \(dupCount, privacy: .public) duplicate transactions")
        } catch {
            logger.error("Failed to detect duplicates: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func fuzzyMatch(_ stored: String, _ parsed: String) -> Bool {
        let storedLower = stored.lowercased()
        let parsedLower = parsed.lowercased()

        if storedLower == parsedLower { return true }
        if storedLower.contains(parsedLower) || parsedLower.contains(storedLower) { return true }

        let storedWords = storedLower.split(separator: " ").map(String.init)
        let parsedWords = parsedLower.split(separator: " ").map(String.init)

        let commonWords = Set(storedWords).intersection(Set(parsedWords))
        return !commonWords.isEmpty && commonWords.count >= min(storedWords.count, parsedWords.count) / 2
    }

    private func isSameTransaction(parsed: ParsedTransaction, existing: Transaction) -> Bool {
        let parsedDate = Calendar.current.startOfDay(for: parsed.postedAt)
        let existingDate = Calendar.current.startOfDay(for: existing.postedAt)

        return parsedDate == existingDate && parsed.amountMinorUnits == existing.amountMinorUnits
    }

    private func fileFormat(for url: URL) -> StatementFileFormat {
        let pathExtension = url.pathExtension.lowercased()
        logger.debug("File extension: '\(pathExtension, privacy: .public)'")

        switch pathExtension {
        case "csv":
            return .csv
        case "xls":
            return .xls
        case "xlsx":
            return .xlsx
        default:
            logger.warning("Unknown extension '\(pathExtension, privacy: .public)', defaulting to CSV")
            return .csv
        }
    }

    private func formatError(_ error: TransactionImportError) -> String {
        switch error {
        case let .unsupportedFormat(format):
            return "Unsupported file format: \(format.rawValue)"
        case let .missingRequiredColumn(column):
            return "Missing required column: \(column)"
        case let .invalidDate(value):
            return "Invalid date format: \(value)"
        case let .invalidAmount(value):
            return "Invalid amount: \(value)"
        case let .malformedFile(description):
            return "File is malformed: \(description)"
        case let .platformUnavailable(description):
            return description
        }
    }

    func createTargetFromDetected(
        customName: String? = nil,
        institutionID: UUID? = nil,
        isCard: Bool? = nil
    ) {
        guard let statement = parsedStatements.first else {
            errorMessage = "No parsed statements available"
            return
        }

        Task {
            do {
                let institution: Institution
                let detectedInstitutionName = statement.institution

                if let providedInstitutionID = institutionID,
                   let found = try await (institutionRepository.fetchInstitutions())
                   .first(where: { $0.id == providedInstitutionID })
                {
                    institution = found
                } else {
                    var existingInstitution: Institution?
                    let existingInstitutions = try await institutionRepository.fetchInstitutions()
                    existingInstitution = existingInstitutions.first { $0.name == detectedInstitutionName }

                    if existingInstitution == nil {
                        existingInstitution = Institution(name: detectedInstitutionName)
                        try await institutionRepository.insert(existingInstitution!)
                    }

                    guard let foundInstitution = existingInstitution else {
                        errorMessage = "Failed to create institution"
                        return
                    }
                    institution = foundInstitution
                }

                let isCardTarget = isCard ?? (statement.cardLast4 != nil)

                if isCardTarget {
                    let cardName = customName ??
                        (statement.cardLast4
                            .map { "\(detectedInstitutionName) Card - \($0)" } ?? "\(detectedInstitutionName) Card")
                    let card = Card(
                        institutionID: institution.id,
                        accountID: nil,
                        name: cardName
                    )

                    try await cardRepository.insert(card)
                    selectedTarget = .card(card.id)
                    cards.append(card)

                    logger.info("Created card: \(cardName)")
                } else {
                    let accountName = customName ??
                        (statement.accountName.isEmpty ? "\(detectedInstitutionName) Account" : statement.accountName)
                    let account = Account(
                        institutionID: institution.id,
                        name: accountName
                    )

                    try await accountRepository.insert(account)
                    selectedTarget = .account(account.id)
                    accounts.append(account)

                    logger.info("Created account: \(accountName)")
                }
            } catch {
                let errorDesc = error.localizedDescription
                logger.error("Failed to create target: \(errorDesc)")
                errorMessage = "Failed to create target: \(errorDesc)"
            }
        }
    }

    private func reset() {
        fileURLs = []
        parsedStatements = []
        selectedTarget = nil
        importResult = nil
        accounts = []
        cards = []
    }
}
