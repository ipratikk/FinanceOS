import FinanceCore
import FinanceOSAPI
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
        guard importSession.selectedTarget == nil else { return }
        guard let statement = importSession.parsedStatements.first else { return }
        if let target = FinanceCore.ImportTargetMatcher.bestTarget(
            for: statement,
            ledgers: ledgers,
            banks: banks
        ) {
            importSession.selectedTarget = target
        }
    }

    func reset() {
        importSession.reset()
        ledgers = []
        banks = []
    }

    // MARK: - Phase Navigation

    func resetToIdle() {
        reset()
        phase = .idle
    }
}
