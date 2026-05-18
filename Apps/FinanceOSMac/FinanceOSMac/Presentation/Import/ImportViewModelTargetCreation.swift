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
        selectedBank: Banks? = nil,
        ownerName: String = "",
        accountType: String = "savings",
        cardType: String = "other",
        cardProduct: String = "",
        isCard: Bool? = nil
    ) async {
        guard let statement = importSession.parsedStatements.first else {
            importSession.errorMessage = ImportError.importFailed(reason: "No parsed statements available").userMessage
            return
        }

        do {
            let bank = try await resolveOrCreateBank(
                for: statement,
                selectedBank: selectedBank
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
                try await createCard(params, cardType: cardType, cardProduct: cardProduct)
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
        if let bankCase = selectedBank {
            let existingBanks = try await bankRepository.fetchBanks()
            if let existing = existingBanks.first(where: { $0.bank == bankCase }) {
                return existing
            }
            let newBank = Bank(bank: bankCase)
            try await bankRepository.insert(newBank)
            return newBank
        }
        let detectedBankName = statement.bankName
        let existingBanks = try await bankRepository.fetchBanks()
        if let existingBank = existingBanks.first(where: { $0.name == detectedBankName }) {
            return existingBank
        }
        let matchingBankCase = Banks.allCases.first { bankCase in
            ImportFormatting.fuzzyMatch(bankCase.displayName, detectedBankName)
        }
        if let bankCase = matchingBankCase {
            let newBank = Bank(bank: bankCase)
            try await bankRepository.insert(newBank)
            return newBank
        }
        throw BankResolutionError(detected: detectedBankName)
    }

    private func createCard(
        _ params: TargetParams,
        cardType: String,
        cardProduct: String = ""
    ) async throws {
        let customNameTrimmed = params.customName?.trimmingCharacters(in: .whitespaces)
        let displayName = customNameTrimmed ?? params.statement.bankName
        let cardDisplayName = !params.last4.isEmpty ?
            "\(displayName) •••• \(params.last4)" :
            displayName

        let ledger = Ledger(
            bankId: params.bank.id,
            kind: .creditCard,
            displayName: cardDisplayName,
            last4: params.last4,
            nickname: params.nickname,
            ownerName: "",
            cardType: cardType,
            cardProduct: cardProduct.isEmpty ? nil : cardProduct
        )
        try await ledgerRepository.insert(ledger)
        ledgers = try await ledgerRepository.fetchLedgers()
        importSession.selectedTarget = .ledger(ledger.id)
        logger.info("Created credit card: \(cardDisplayName)")
    }

    private func createAccount(
        _ params: TargetParams,
        ownerName: String = "",
        accountType: String
    ) async throws {
        let customNameTrimmed = params.customName?.trimmingCharacters(in: .whitespaces)
        let displayName = customNameTrimmed ?? params.statement.bankName
        let accountDisplayName = !params.last4.isEmpty ?
            "\(displayName) •••• \(params.last4)" :
            displayName

        let ledger = Ledger(
            bankId: params.bank.id,
            kind: .bankAccount,
            displayName: accountDisplayName,
            last4: params.last4,
            nickname: params.nickname,
            ownerName: ownerName,
            accountType: accountType
        )
        try await ledgerRepository.insert(ledger)
        ledgers = try await ledgerRepository.fetchLedgers()
        importSession.selectedTarget = .ledger(ledger.id)
        logger.info("Created bank account: \(accountDisplayName)")
    }
}
