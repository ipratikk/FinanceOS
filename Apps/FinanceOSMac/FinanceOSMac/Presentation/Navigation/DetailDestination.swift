import Foundation

/// Typed destinations for push navigation within the detail column.
/// Used as values for NavigationPath in AppNavigator.
enum DetailDestination: Hashable {
    case accountTransactions(String)
    case cardTransactions(String)
    case ledgerDetail(String)
}
