//
//  AppContainer.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

@MainActor
public final class AppContainer {
    public static let shared: AppContainer = {
        do {
            let databaseManager = DatabaseManager.shared
            return AppContainer(databaseManager: databaseManager)
        } catch {
            fatalError("Failed to initialize AppContainer: \(error)")
        }
    }()

    public let transactionRepository: any TransactionRepository
    public let bankRepository: any BankRepository
    public let ledgerRepository: any LedgerRepository

    public let transactionImportPipeline: TransactionImportPipeline

    public let spendingService: any SpendingServiceProtocol

    public init(databaseManager: DatabaseManager = DatabaseManager.shared) {
        transactionRepository = GRDBTransactionRepository(
            dbQueue: databaseManager.dbQueue
        )

        bankRepository = GRDBBankRepository(
            dbQueue: databaseManager.dbQueue
        )

        ledgerRepository = GRDBLedgerRepository(
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
