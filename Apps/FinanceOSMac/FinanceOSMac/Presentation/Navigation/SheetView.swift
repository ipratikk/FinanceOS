import FinanceCore
import SwiftUI

struct SheetView: View {
    let route: SheetRoute
    let appContainer: AppContainer

    var body: some View {
        switch route {
        case let .bankEdit(bank):
            let context = BankEditContext(repository: appContainer.bankRepository)
            BankEditView(bank: bank, context: context)
        default:
            EmptyView()
        }
    }
}
