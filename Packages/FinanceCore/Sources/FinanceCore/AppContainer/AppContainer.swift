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

    public let bankRepository: any BankRepository

    public let transactionImportPipeline: TransactionImportPipeline

    public let spendingService: any SpendingServiceProtocol

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

        bankRepository = GRDBBankRepository(
            dbQueue: databaseManager.dbQueue
        )

        transactionImportPipeline = TransactionImportPipeline(
            repository: transactionRepository
        )

        spendingService = GRDBSpendingService(
            dbQueue: databaseManager.dbQueue,
            transactionRepository: transactionRepository
        )
    }
}
