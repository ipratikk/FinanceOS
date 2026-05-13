//
//  AppContainer.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

@MainActor
public final class AppContainer {
    public static let shared = AppContainer()

    public let accountRepository: any AccountRepository
    public let cardRepository: any CardRepository

    public let institutionRepository: any InstitutionRepository

    private init() {
        let databaseManager = DatabaseManager.shared

        accountRepository = GRDBAccountRepository(
            dbQueue: databaseManager.dbQueue
        )

        cardRepository = GRDBCardRepository(
            dbQueue: databaseManager.dbQueue
        )

        institutionRepository = GRDBInstitutionRepository(
            dbQueue: databaseManager.dbQueue
        )
    }
}
