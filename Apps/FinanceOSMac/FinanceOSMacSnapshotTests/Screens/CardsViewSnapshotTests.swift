import FinanceCore
@testable import FinanceOSMac
import FinanceTesting
import SnapshotTesting
import SwiftUI
import XCTest

final class CardsViewSnapshotTests: SnapshotTestable {
    override var record: Bool { false }

    func test_cards_view() {
        let ledgerRepo = MockLedgerRepository()
        let bankRepo = MockBankRepository()
        let transactionRepo = MockTransactionRepository()
        let viewModel = CardsViewModel(
            ledgerRepository: ledgerRepo,
            bankRepository: bankRepo,
            transactionRepository: transactionRepo
        )
        viewModel.banks = PreviewBanks.all
        viewModel.accounts = PreviewLedgers.all.filter { $0.kind == .bankAccount }
        let cards = PreviewLedgers.all.filter { $0.kind == .creditCard }
        viewModel.cardRows = cards.map { card in
            CardsViewModel.CardRow(
                id: card.id,
                card: card,
                title: card.displayName,
                institutionName: "American Express",
                linkedAccountName: "Checking"
            )
        }

        let view = CardsView(
            viewModel: viewModel,
            transactionRepository: transactionRepo,
            ledgerRepository: ledgerRepo
        )
        verifySnapshots(view)
    }
}
