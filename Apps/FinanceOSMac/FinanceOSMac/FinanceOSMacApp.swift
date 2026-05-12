import FinanceCore
import SwiftUI

@main
struct FinanceOSMacApp: App {
    private let institutionRepository =
        GRDBInstitutionRepository(
            dbQueue: DatabaseManager.shared.dbQueue
        )

    var body: some Scene {
        WindowGroup {
            InstitutionsView(
                viewModel: InstitutionsViewModel(
                    repository: institutionRepository
                )
            )
        }
    }
}
