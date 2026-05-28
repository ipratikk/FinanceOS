import SwiftUI

public extension EnvironmentValues {
    @Entry var transactionIntelligence: (any TransactionIntelligenceService)?
}
