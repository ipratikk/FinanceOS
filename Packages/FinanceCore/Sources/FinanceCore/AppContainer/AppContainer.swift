//
//  AppContainer.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

/// Composition root for the application's object graph.
/// Owns all repository instances, the import pipeline, and the spending service.
/// Access via `AppContainer.shared` from ViewModels; never inject individual GRDB types directly.
@MainActor
public final class AppContainer {
    /// Singleton entry point. All ViewModels should depend on this rather than constructing
    /// repositories independently.
    public static let shared = AppContainer()

    /// GraphQL client wired to the local backend at localhost:4000.
    public let graphQLClient: ApolloGraphQLClient = {
        let urlString = ProcessInfo.processInfo.environment["GRAPHQL_URL"] ?? "http://localhost:4000/graphql"
        // swiftlint:disable:next force_unwrapping
        return ApolloGraphQLClient(url: URL(string: urlString)!)
    }()

    public let transactionRepository: any TransactionRepository
    public let bankRepository: any BankRepository
    public let ledgerRepository: any LedgerRepository
    public let spendingService: any SpendingServiceProtocol

    private init() {
        let databaseManager = DatabaseManager.shared

        transactionRepository = GRDBTransactionRepository(
            dbQueue: databaseManager.dbQueue
        )

        bankRepository = GRDBBankRepository(
            dbQueue: databaseManager.dbQueue
        )

        ledgerRepository = GRDBLedgerRepository(
            dbQueue: databaseManager.dbQueue
        )

        spendingService = GRDBSpendingService(
            dbQueue: databaseManager.dbQueue,
            transactionRepository: transactionRepository,
            ledgerRepository: ledgerRepository
        )
    }
}
