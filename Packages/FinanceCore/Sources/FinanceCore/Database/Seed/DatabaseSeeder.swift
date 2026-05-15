//
//  DatabaseSeeder.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation
import GRDB

enum DatabaseSeeder {
    private static let defaultAccountDefinitions = [
        ("HDFC", "HDFC Bank Account"),
        ("ICICI", "ICICI Bank Account")
    ]

    private static let defaultCardDefinitions = [
        ("HDFC", "HDFC", "HDFC Regalia"),
        ("ICICI", "ICICI", "ICICI Coral"),
        ("ICICI", "ICICI", "ICICI Amazon Pay"),
        ("Amex", nil, "American Express Platinum Travel"),
        ("Scapia", nil, "Scapia")
    ]

    private static let defaultTransactionDefinitions: [(
        sourceType: String,
        sourceName: String,
        description: String,
        amountMinorUnits: Int64,
        currencyCode: String,
        sourceFingerprint: String
    )] = [
        ("account", "HDFC Bank Account", "Salary Credit", 25_000_000, "INR", "seed_salary_credit"),
        ("card", "HDFC Regalia", "Airport Lounge Meal", -125_000, "INR", "seed_hdfc_regalia_meal"),
        ("card", "ICICI Amazon Pay", "Online Shopping", -349_900, "INR", "seed_icici_amazon_pay_shopping")
    ]

    static func seedBanks(
        in database: Database
    ) throws {
        let existingBankCount = try Bank
            .fetchCount(database)

        guard existingBankCount == 0 else {
            return
        }

        let banks = [
            Bank(name: "HDFC", providerType: .bank),
            Bank(name: "ICICI", providerType: .bank),
            Bank(name: "Amex", providerType: .credit),
            Bank(name: "Scapia", providerType: .bank)
        ]

        for bank in banks {
            try bank.insert(database)
        }

        FinanceLogger.database.info(
            "Seeded default banks"
        )
    }

    static func seedAccounts(
        in database: Database
    ) throws {
        let existingAccountCount = try Account
            .fetchCount(database)

        guard existingAccountCount == 0 else {
            return
        }

        let banks = try Bank
            .fetchAll(database)

        let bankIDsByName = Dictionary(
            uniqueKeysWithValues: banks.map { bank in
                (bank.name, bank.id)
            }
        )

        for (bankName, accountName) in defaultAccountDefinitions {
            guard let bankID = bankIDsByName[bankName] else {
                continue
            }

            let account = Account(
                bankId: bankID,
                accountName: accountName
            )

            try account.insert(database)
        }

        FinanceLogger.database.info(
            "Seeded default accounts"
        )
    }

    static func seedCards(
        in database: Database
    ) throws {
        let existingCardCount = try Card
            .fetchCount(database)

        guard existingCardCount == 0 else {
            return
        }

        let banks = try Bank
            .fetchAll(database)
        let accounts = try Account
            .fetchAll(database)

        let bankIDsByName = Dictionary(
            uniqueKeysWithValues: banks.map { bank in
                (bank.name, bank.id)
            }
        )

        let accountIDsByBankName = Dictionary(
            uniqueKeysWithValues: accounts.compactMap { account in
                banks
                    .first { bank in
                        bank.id == account.bankId
                    }
                    .map { bank in
                        (bank.name, account.id)
                    }
            }
        )

        for (bankName, linkedAccountBankName, cardName) in defaultCardDefinitions {
            guard let bankID = bankIDsByName[bankName] else {
                continue
            }

            let card = Card(
                bankId: bankID,
                linkedAccountId: linkedAccountBankName.flatMap { bankName in
                    accountIDsByBankName[bankName]
                },
                cardName: cardName
            )

            try card.insert(database)
        }

        FinanceLogger.database.info(
            "Seeded default cards"
        )
    }

    static func seedTransactions(
        in database: Database
    ) throws {
        let existingTransactionCount = try Transaction
            .fetchCount(database)

        guard existingTransactionCount == 0 else {
            return
        }

        let accounts = try Account
            .fetchAll(database)
        let cards = try Card
            .fetchAll(database)

        let accountsByName = Dictionary(
            uniqueKeysWithValues: accounts.map { account in
                (account.accountName, account)
            }
        )

        let cardsByName = Dictionary(
            uniqueKeysWithValues: cards.map { card in
                (card.cardName, card)
            }
        )

        let calendar = Calendar(identifier: .gregorian)
        let transactionDates = [
            calendar.date(from: DateComponents(year: 2026, month: 5, day: 1)),
            calendar.date(from: DateComponents(year: 2026, month: 5, day: 3)),
            calendar.date(from: DateComponents(year: 2026, month: 5, day: 5))
        ].compactMap(\.self)

        for (index, definition) in defaultTransactionDefinitions.enumerated() {
            guard transactionDates.indices.contains(index) else {
                continue
            }

            let (
                sourceType,
                sourceName,
                description,
                amountMinorUnits,
                currencyCode,
                sourceFingerprint
            ) = definition

            let transaction: Transaction? = switch sourceType {
            case "account":
                accountsByName[sourceName].map { account in
                    Transaction(
                        accountID: account.id,
                        postedAt: transactionDates[index],
                        description: description,
                        amountMinorUnits: amountMinorUnits,
                        currencyCode: currencyCode,
                        sourceFingerprint: sourceFingerprint
                    )
                }

            case "card":
                cardsByName[sourceName].map { card in
                    Transaction(
                        cardID: card.id,
                        postedAt: transactionDates[index],
                        description: description,
                        amountMinorUnits: amountMinorUnits,
                        currencyCode: currencyCode,
                        sourceFingerprint: sourceFingerprint
                    )
                }

            default:
                nil
            }

            if let transaction {
                try transaction.insert(database)
            }
        }

        FinanceLogger.database.info(
            "Seeded default transactions"
        )
    }
}
