import FinanceCore
import SwiftUI

@main
struct FinanceOSMacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }

        Settings {
            SettingsView()
                .preferredColorScheme(.dark)
        }
    }
}
