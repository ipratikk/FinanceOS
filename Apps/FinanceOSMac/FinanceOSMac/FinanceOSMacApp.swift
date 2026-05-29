import FinanceCore
import FinanceIntelligence
import SwiftUI

@main
struct FinanceOSMacApp: App {
    @State private var intelligenceService: (any TransactionIntelligenceService)?
    @State private var categorizationScheduler: CategorizationScheduler?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    let service = await TransactionIntelligenceServiceImpl()
                    intelligenceService = service
                    let scheduler = CategorizationScheduler(
                        transactionRepository: AppContainer.shared.transactionRepository,
                        intelligenceService: service
                    )
                    categorizationScheduler = scheduler
                    Task.detached(priority: .background) {
                        await scheduler.run()
                    }
                }
                .environment(\.transactionIntelligence, intelligenceService)
                .environment(\.categorizationScheduler, categorizationScheduler)
                .preferredColorScheme(.dark)
        }

        Settings {
            SettingsView()
                .preferredColorScheme(.dark)
        }
    }
}
