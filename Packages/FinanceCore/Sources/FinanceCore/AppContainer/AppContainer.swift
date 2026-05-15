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

    public let transactionImporter: any TransactionImporting
    public let transactionImportPipeline: TransactionImportPipeline
    public let parserRegistry: StatementParserRegistry

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

        parserRegistry = StatementParserRegistry(
            parsers: [
                ICICIBankStatementParser(),
                ICICICardStatementParser(),
                HDFCBankStatementParser(),
                HDFCCardStatementParser(),
                AmexCardStatementParser()
            ]
        )

        transactionImporter = DefaultTransactionImporter()

        transactionImportPipeline = TransactionImportPipeline(
            repository: transactionRepository
        )
    }
}
