import FinanceCore
import Foundation

extension ImportViewModel {
    func createTargetFromDetected(
        customName: String? = nil,
        nickname: String = "",
        last4: String = "",
        bankID: UUID? = nil,
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
            let isCardTarget = isCard ?? (statement.cardLast4 != nil)
            if isCardTarget {
                try await createCard(bank, statement, customName, last4, cardType, nickname)
            } else {
                try await createAccount(bank, statement, customName, last4, accountType, nickname)
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
        if let providedBankID,
           let found = try await bankRepository.fetchBanks()
           .first(where: { $0.id == providedBankID })
        {
            return found
        }
        let existingBanks = try await bankRepository.fetchBanks()
        if let existingBank = existingBanks.first(where: { $0.name == detectedBankName }) {
            return existingBank
        }
        let newBank = Bank(name: detectedBankName, providerType: .bank)
        try await bankRepository.insert(newBank)
        return newBank
    }

    private func createCard(
        _ bank: Bank,
        _ statement: ParsedStatement,
        _ customName: String?,
        _ last4: String,
        _ cardType: CardType,
        _ nickname: String
    ) async throws {
        let cardName = customName ??
            (statement.cardLast4
                .map { "\(statement.bankName) Card - \($0)" } ??
                "\(statement.bankName) Card")
        let card = Card(
            bankId: bank.id,
            linkedAccountId: nil,
            cardName: cardName,
            cardLast4: last4,
            cardType: cardType,
            nickname: nickname
        )
        try await cardRepository.insert(card)
        selectedTarget = .card(card.id)
        cards.append(card)
        logger.info("Created card: \(cardName)")
    }

    private func createAccount(
        _ bank: Bank,
        _ statement: ParsedStatement,
        _ customName: String?,
        _ last4: String,
        _ accountType: AccountType,
        _ nickname: String
    ) async throws {
        let accountName = customName ??
            (statement.accountName.isEmpty ?
                "\(statement.bankName) Account" :
                statement.accountName)
        let account = Account(
            bankId: bank.id,
            accountName: accountName,
            accountLast4: last4,
            accountType: accountType,
            nickname: nickname
        )
        try await accountRepository.insert(account)
        selectedTarget = .account(account.id)
        accounts.append(account)
        logger.info("Created account: \(accountName)")
    }
}
