import Foundation

/// Typed destinations for push navigation within the detail column.
/// Used as values for NavigationPath in AppNavigator.
enum DetailDestination: Hashable {
    case accountTransactions(UUID)
    case cardTransactions(UUID)
    case ledgerDetail(UUID)
}
