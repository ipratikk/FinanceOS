import FinanceCore
import FinanceUI
import os
import SwiftUI

@main
struct FinanceOSMacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .fdsAdaptive()
                .preferredColorScheme(.dark)
        }

        Settings {
            SettingsView(viewModel: SettingsViewModel(graphQLClient: AppContainer.shared.graphQLClient))
                .preferredColorScheme(.dark)
        }
    }
}
