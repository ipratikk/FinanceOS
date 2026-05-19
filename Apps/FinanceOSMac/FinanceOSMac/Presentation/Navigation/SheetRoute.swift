import FinanceCore

/// Typed sheet/modal routes for the entire app.
/// Single enum that drives all modal presentations, replacing scattered boolean/@State variables.
enum SheetRoute: Identifiable {
    case accountEdit(Ledger)
    case cardEdit(Ledger)
    case bankEdit(Bank)
    case transactionDetail(TransactionRow)
    case transactionFilter(TransactionListState)
    case importCreateTarget
    case passwordPrompt

    var id: String {
        switch self {
        case let .accountEdit(ledger):
            "accountEdit-\(ledger.id)"
        case let .cardEdit(ledger):
            "cardEdit-\(ledger.id)"
        case let .bankEdit(bank):
            "bankEdit-\(bank.id)"
        case let .transactionDetail(row):
            "txn-\(row.id)"
        case .transactionFilter:
            "filter"
        case .importCreateTarget:
            "importCreate"
        case .passwordPrompt:
            "password"
        }
    }
}
