import FinanceCore
import FinanceIntelligence
import SwiftUI

@main
struct FinanceOSMacApp: App {
    @State private var intelligenceService: (any TransactionIntelligenceService)?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    intelligenceService = await TransactionIntelligenceServiceImpl()
                }
                .environment(\.transactionIntelligence, intelligenceService)
                .preferredColorScheme(.dark)
        }

        Settings {
            SettingsView()
                .preferredColorScheme(.dark)
        }
    }
}
