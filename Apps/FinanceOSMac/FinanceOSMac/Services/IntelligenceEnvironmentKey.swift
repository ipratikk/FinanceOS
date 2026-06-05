import FinanceIntelligence
import SwiftUI

extension EnvironmentValues {
    /// The intelligence service injected into the SwiftUI environment.
    /// Nil until `TransactionIntelligenceServiceImpl` is initialized and injected at the app root.
    @Entry var transactionIntelligence: (any TransactionIntelligenceService)?
}
