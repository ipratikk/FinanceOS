import FinanceCore
import FinanceIntelligence
import os
import SwiftUI

@main
struct FinanceOSMacApp: App {
    @State private var intelligenceService: (any TransactionIntelligenceService)?
    @State private var categorizationScheduler: CategorizationScheduler?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Pass the shared database queue so post-processing pipeline
                    // (graph, recurring, relationships) has persistence backing.
                    do {
                        let config = try IntelligenceServiceConfiguration(
                            correctionStoreURL: IntelligenceServiceConfiguration.default.correctionStoreURL,
                            personalizedKNNModelURL: IntelligenceServiceConfiguration.default.personalizedKNNModelURL,
                            databaseQueue: DatabaseManager.shared.dbQueue
                        )
                        let service = await TransactionIntelligenceServiceImpl(configuration: config)
                        intelligenceService = service
                        let scheduler = CategorizationScheduler(
                            transactionRepository: AppContainer.shared.transactionRepository,
                            intelligenceService: service
                        )
                        categorizationScheduler = scheduler
                        Task.detached(priority: .background) {
                            await scheduler.run()
                        }
                    } catch {
                        FinanceLogger.intelligence.error("Failed to initialize intelligence service: \(error)")
                    }
                }
                .environment(\.transactionIntelligence, intelligenceService)
                .environment(\.categorizationScheduler, categorizationScheduler)
                .preferredColorScheme(.dark)
        }

        Settings {
            SettingsView(viewModel: SettingsViewModel(bankRepository: AppContainer.shared.bankRepository))
                .preferredColorScheme(.dark)
        }
    }
}
