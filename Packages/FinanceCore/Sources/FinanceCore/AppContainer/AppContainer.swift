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

    public let institutionRepository: any InstitutionRepository

    private init() {
        let databaseManager = DatabaseManager.shared

        institutionRepository = GRDBInstitutionRepository(
            dbQueue: databaseManager.dbQueue
        )
    }
}
