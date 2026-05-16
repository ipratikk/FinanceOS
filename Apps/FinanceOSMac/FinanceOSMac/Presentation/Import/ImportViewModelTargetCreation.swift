import FinanceCore
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
        bankID: UUID? = nil,
        ownerName: String = "",
        accountType: AccountType = .savings,
        cardType: CardType = .other,
        isCard: Bool? = nil
    ) async {
        guard let statement = parsedStatements.first else {
            errorMessage = "No parsed statements available"
            return
        }

        do {
            let bank = try await resolveOrCreateBank(
                for: statement,
                providedBankID: bankID
            )
            let params = TargetParams(
                bank: bank,
                statement: statement,
                customName: customName,
                last4: last4,
                nickname: nickname
            )
            let isCardTarget = isCard ?? (statement.cardLast4 != nil)
            if isCardTarget {
                try await createCard(params, cardType: cardType)
            } else {
                try await createAccount(params, ownerName: ownerName, accountType: accountType)
            }
        } catch {
            let errorDesc = error.localizedDescription
            logger.error("Failed to create target: \(errorDesc)")
            errorMessage = "Failed to create target: \(errorDesc)"
        }
    }

    private func resolveOrCreateBank(
        for statement: ParsedStatement,
        providedBankID: UUID?
    ) async throws -> Bank {
        let detectedBankName = statement.bankName
        // swiftformat:disable all
        if let providedBankID,
           let found = try await bankRepository.fetchBanks()
           .first(where: { $0.id == providedBankID }) {
            return found
        }
        // swiftformat:enable all
        let existingBanks = try await bankRepository.fetchBanks()
        if let existingBank = existingBanks.first(where: { $0.name == detectedBankName }) {
            return existingBank
        }
        let newBank = Bank(name: detectedBankName, providerType: .bank)
        try await bankRepository.insert(newBank)
        return newBank
    }

    private func createCard(
        _ params: TargetParams,
        cardType: CardType
    ) async throws {
        let customNameTrimmed = params.customName?.trimmingCharacters(in: .whitespaces)
        let displayName = customNameTrimmed ?? params.statement.bankName
        let cardName = !params.last4.isEmpty ?
            "\(displayName) •••• \(params.last4)" :
            displayName
        let card = Card(
            bankId: params.bank.id,
            linkedAccountId: nil,
            cardName: cardName,
            cardLast4: params.last4,
            cardType: cardType,
            nickname: params.nickname
        )
        try await cardRepository.insert(card)
        selectedTarget = .ledger(card.id)
        logger.info("Created card: \(cardName)")
    }

    private func createAccount(
        _ params: TargetParams,
        ownerName: String = "",
        accountType: AccountType
    ) async throws {
        let customNameTrimmed = params.customName?.trimmingCharacters(in: .whitespaces)
        let displayName = customNameTrimmed ?? params.statement.bankName
        let accountName = !params.last4.isEmpty ?
            "\(displayName) •••• \(params.last4)" :
            displayName
        let account = Account(
            bankId: params.bank.id,
            accountName: accountName,
            accountLast4: params.last4,
            ownerName: ownerName,
            accountType: accountType,
            nickname: params.nickname
        )
        try await accountRepository.insert(account)
        selectedTarget = .ledger(account.id)
        logger.info("Created account: \(accountName)")
    }
}
