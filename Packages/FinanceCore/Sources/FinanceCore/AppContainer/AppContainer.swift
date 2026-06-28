//
//  AppContainer.swift
//  FinanceCore
//
//  Created by Pratik Goel on 13/05/26.
//

import Foundation

/// Composition root for the application's object graph.
/// Owns the GraphQL client and the transaction repository (used by CategorizationScheduler).
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

    /// Used only by CategorizationScheduler in FinanceIntelligence (via FinanceOSMacApp)
    public let transactionRepository: any TransactionRepository

    private init() {
        let databaseManager = DatabaseManager.shared
        transactionRepository = GRDBTransactionRepository(dbQueue: databaseManager.dbQueue)
    }
}
