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

    static func seedInstitutions(
        in database: Database
    ) throws {
        let existingInstitutionCount = try Institution
            .fetchCount(database)

        guard existingInstitutionCount == 0 else {
            return
        }

        let institutions = [
            Institution(name: "HDFC"),
            Institution(name: "ICICI"),
            Institution(name: "Amex"),
            Institution(name: "Scapia")
        ]

        for institution in institutions {
            try institution.insert(database)
        }

        FinanceLogger.database.info(
            "Seeded default institutions"
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

        let institutions = try Institution
            .fetchAll(database)

        let institutionIDsByName = Dictionary(
            uniqueKeysWithValues: institutions.map { institution in
                (institution.name, institution.id)
            }
        )

        for (institutionName, accountName) in defaultAccountDefinitions {
            guard let institutionID = institutionIDsByName[institutionName] else {
                continue
            }

            let account = Account(
                institutionID: institutionID,
                name: accountName
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

        let institutions = try Institution
            .fetchAll(database)
        let accounts = try Account
            .fetchAll(database)

        let institutionIDsByName = Dictionary(
            uniqueKeysWithValues: institutions.map { institution in
                (institution.name, institution.id)
            }
        )

        let accountIDsByInstitutionName = Dictionary(
            uniqueKeysWithValues: accounts.compactMap { account in
                institutions
                    .first { institution in
                        institution.id == account.institutionID
                    }
                    .map { institution in
                        (institution.name, account.id)
                    }
            }
        )

        for (institutionName, linkedAccountInstitutionName, cardName) in defaultCardDefinitions {
            guard let institutionID = institutionIDsByName[institutionName] else {
                continue
            }

            let card = Card(
                institutionID: institutionID,
                accountID: linkedAccountInstitutionName.flatMap { institutionName in
                    accountIDsByInstitutionName[institutionName]
                },
                name: cardName
            )

            try card.insert(database)
        }

        FinanceLogger.database.info(
            "Seeded default cards"
        )
    }
}
