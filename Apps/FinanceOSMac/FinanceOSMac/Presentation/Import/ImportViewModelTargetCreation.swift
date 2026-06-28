import FinanceCore
import FinanceOSAPI
import FinanceParsers
import Foundation
import OSLog

extension ImportViewModel {
    private struct TargetParams {
        let bank: Bank
        let statement: ParsedStatement
        let customName: String?
        let last4: String
        let nickname: String
    }

    func createTargetFromDetected(
        customName: String? = nil,
        nickname: String = "",
        last4: String = "",
        selectedBank: Banks? = nil,
        ownerName: String = "",
        accountType: String = "savings",
        cardType: CardNetwork = .other,
        cardProductId: String = "",
        encryptedCardNumber: String = "",
        linkedLedgerId: UUID? = nil,
        isCard: Bool? = nil
    ) async {
        guard let statement = importSession.parsedStatements.first else {
            importSession.errorMessage = ImportError.importFailed(reason: "No parsed statements available").userMessage
            return
        }
        do {
            let bank = try await resolveOrCreateBank(for: statement, selectedBank: selectedBank)
            let params = TargetParams(
                bank: bank,
                statement: statement,
                customName: customName,
                last4: last4,
                nickname: nickname
            )
            let isCardTarget = isCard ?? (statement.cardLast4 != nil)
            if isCardTarget {
                try await createCard(
                    params,
                    ownerName: ownerName,
                    cardType: cardType,
                    cardProductId: cardProductId,
                    encryptedCardNumber: encryptedCardNumber,
                    linkedLedgerId: linkedLedgerId
                )
            } else {
                try await createAccount(params, ownerName: ownerName, accountType: accountType)
            }
        } catch {
            let errorDesc = error.localizedDescription
            logger.error("Failed to create target: \(errorDesc)")
            importSession.errorMessage = "Failed to create target: \(errorDesc)"
        }
    }

    private func resolveOrCreateBank(
        for statement: ParsedStatement,
        selectedBank: Banks?
    ) async throws -> Bank {
        let bankData = try await graphQLClient.fetch(query: GetBanksQuery())
        let existingBanks = bankData.banks.map(GraphQLMappings.mapBank)
        if let bankCase = selectedBank {
            if let existing = existingBanks.first(where: { $0.bank == bankCase }) {
                return existing
            }
            return try await makeBank(bankCase)
        }
        let detectedBankName = statement.bankName
        if let existingBank = existingBanks.first(where: { $0.name == detectedBankName }) {
            return existingBank
        }
        let matchingBankCase = Banks.allCases.first { bankCase in
            ImportHelpers.fuzzyMatch(bankCase.displayName, detectedBankName)
        }
        if let bankCase = matchingBankCase {
            return try await makeBank(bankCase)
        }
        throw BankResolutionError(detected: detectedBankName)
    }

    private func makeBank(_ bankCase: Banks) async throws -> Bank {
        let data = try await graphQLClient.perform(
            mutation: CreateBankMutation(input: CreateBankInput(
                name: bankCase.displayName,
                code: bankCase.rawValue
            ))
        )
        return Bank(
            id: UUID(uuidString: data.createBank.id) ?? UUID(),
            bank: bankCase
        )
    }

    private func createCard(
        _ params: TargetParams,
        ownerName: String = "",
        cardType: CardNetwork,
        cardProductId: String = "",
        encryptedCardNumber: String = "",
        linkedLedgerId: UUID? = nil
    ) async throws {
        let customNameTrimmed = params.customName?.trimmingCharacters(in: .whitespaces)
        let displayName = customNameTrimmed ?? params.statement.bankName
        let cardDisplayName = !params.last4
            .isEmpty ? "\(displayName) \u{2022}\u{2022}\u{2022}\u{2022} \(params.last4)" : displayName
        let input = CreateLedgerInput(
            displayName: cardDisplayName,
            kind: .init(.creditCard),
            last4: params.last4.isEmpty ? .none : .some(params.last4),
            bankId: params.bank.id.uuidString
        )
        let result = try await graphQLClient.perform(mutation: CreateLedgerMutation(input: input))
        importSession.selectedTarget = .ledger(UUID(uuidString: result.createLedger.id) ?? UUID())
        let ledgerData = try await graphQLClient.fetch(query: GetLedgersQuery())
        ledgers = ledgerData.ledgers.map(GraphQLMappings.mapLedger)
        let encryptedStatus = encryptedCardNumber.isEmpty ? "not provided" : "provided"
        logger.info("Created credit card: \(cardDisplayName) [encrypted: \(encryptedStatus)]")
    }

    private func createAccount(
        _ params: TargetParams,
        ownerName: String = "",
        accountType: String
    ) async throws {
        let customNameTrimmed = params.customName?.trimmingCharacters(in: .whitespaces)
        let displayName = customNameTrimmed ?? params.statement.bankName
        let accountDisplayName = !params.last4.isEmpty
            ? "\(displayName) \u{2022}\u{2022}\u{2022}\u{2022} \(params.last4)"
            : displayName
        let input = CreateLedgerInput(
            displayName: accountDisplayName,
            kind: .init(.bankAccount),
            last4: params.last4.isEmpty ? .none : .some(params.last4),
            bankId: params.bank.id.uuidString
        )
        let result = try await graphQLClient.perform(mutation: CreateLedgerMutation(input: input))
        importSession.selectedTarget = .ledger(UUID(uuidString: result.createLedger.id) ?? UUID())
        let ledgerData = try await graphQLClient.fetch(query: GetLedgersQuery())
        ledgers = ledgerData.ledgers.map(GraphQLMappings.mapLedger)
        logger.info("Created bank account: \(accountDisplayName)")
    }
}
