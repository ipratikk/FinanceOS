import FinanceCore
import SwiftUI

@main
struct FinanceOSMacApp: App {
    private let appContainer = AppContainer.shared

    var body: some Scene {
        WindowGroup {
            InstitutionsView(
                viewModel: InstitutionsViewModel(
                    repository: appContainer.institutionRepository
                )
            )
        }
    }
}
