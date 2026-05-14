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
    public let transactionRepository: any TransactionRepository

    public let institutionRepository: any InstitutionRepository

    public let transactionImporter: any TransactionImporting
    public let transactionImportPipeline: TransactionImportPipeline

    private init() {
        let databaseManager = DatabaseManager.shared

        accountRepository = GRDBAccountRepository(
            dbQueue: databaseManager.dbQueue
        )

        cardRepository = GRDBCardRepository(
            dbQueue: databaseManager.dbQueue
        )

        transactionRepository = GRDBTransactionRepository(
            dbQueue: databaseManager.dbQueue
        )

        institutionRepository = GRDBInstitutionRepository(
            dbQueue: databaseManager.dbQueue
        )

        transactionImporter = DefaultTransactionImporter()

        transactionImportPipeline = TransactionImportPipeline(
            importer: transactionImporter,
            repository: transactionRepository
        )
    }
}
