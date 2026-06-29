import FinanceCore
import FinanceIntelligence
import FinanceUI
import Network
import os
import SwiftUI

@main
struct FinanceOSMacApp: App {
    @State private var intelligenceService: (any TransactionIntelligenceService)?
    @State private var categorizationScheduler: CategorizationScheduler?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .fdsAdaptive()
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
                            graphQLClient: AppContainer.shared.graphQLClient,
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
                .task(priority: .background) {
                    await attemptSilentModelDownload()
                }
        }

        Settings {
            SettingsView(viewModel: SettingsViewModel(graphQLClient: AppContainer.shared.graphQLClient))
                .preferredColorScheme(.dark)
        }
    }

    private func attemptSilentModelDownload() async {
        let manager = ModelDownloadManager.shared
        guard await !manager.isReady else { return }

        let isOnWifi = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
            let queue = DispatchQueue(label: "finos.model.network.monitor", qos: .background)
            monitor.pathUpdateHandler = { path in
                monitor.cancel()
                continuation.resume(returning: path.status == .satisfied)
            }
            monitor.start(queue: queue)
        }

        guard isOnWifi else { return }
        await manager.download()
    }
}
