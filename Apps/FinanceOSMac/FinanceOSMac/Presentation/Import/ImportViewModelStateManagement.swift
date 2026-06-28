import FinanceCore
import FinanceOSAPI
import FinanceParsers
import Foundation
import OSLog

extension ImportViewModel {
    func loadTargetsOnAppear() async {
        do {
            logger.debug("Loading ledgers and banks via GraphQL")
            let ledgerData = try await graphQLClient.fetch(query: GetLedgersQuery())
            let bankData = try await graphQLClient.fetch(query: GetBanksQuery())
            ledgers = ledgerData.ledgers.map(GraphQLMappings.mapLedger)
            banks = bankData.banks.map(GraphQLMappings.mapBank)
            logger.logDebug("Loaded {ledgers} ledgers and {banks} banks", [
                "ledgers": ledgers.count,
                "banks": banks.count
            ])
        } catch {
            let errorMsg = error.localizedDescription
            logger.error("Failed to load targets: \(errorMsg, privacy: .public)")
            importSession.errorMessage = errorMsg
        }
    }

    func autoSelectMatchingTarget() async {
        guard let statement = importSession.parsedStatements.first else { return }
        if let target = FinanceCore.ImportTargetMatcher.bestTarget(
            for: statement,
            ledgers: ledgers,
            banks: banks
        ) {
            importSession.selectedTarget = target
            await detectDuplicates(for: target)
        }
    }

    func detectDuplicates(for target: TransactionImportTarget?) async {
        let detector = duplicateDetector
        let (skipAll, inDB) = detector.detect(
            statements: importSession.parsedStatements,
            existingTransactions: []
        )

        logger.logInfo(
            "Dedup: {indb} in DB, {batch} batch-only, {new} new",
            [
                "indb": String(inDB.count),
                "batch": String(skipAll.count - inDB.count),
                "new": String(importSession.parsedStatements.flatMap(\.transactions).count - skipAll.count)
            ]
        )

        duplicateTransactionIndices = skipAll
        alreadyInDBIndices = inDB
    }

    func reset() {
        importSession.reset()
        ledgers = []
        banks = []
        duplicateTransactionIndices = []
        alreadyInDBIndices = []
    }

    // MARK: - Step Navigation

    func selectSourceAndAdvance(_ source: StatementSource) {
        setSource(source)
        currentStep = .upload
    }

    func advanceToReview() {
        currentStep = .review
    }

    func resetToSource() {
        reset()
        currentStep = .source
    }

    func backToUpload() {
        parsedStatements = []
        selectedTarget = nil
        duplicateTransactionIndices = []
        alreadyInDBIndices = []
        currentStep = .upload
    }
}
