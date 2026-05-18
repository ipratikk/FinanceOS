import FinanceCore
import FinanceParsers
import SwiftUI

extension ImportPreviewView {
    var targetSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Import To")
                .font(.headline)

            Menu {
                if viewModel.selectedTarget != nil {
                    Button(action: {
                        viewModel.selectedTarget = nil
                    }) {
                        Text("Clear Selection")
                    }
                    Divider()
                }

                let accounts = viewModel.ledgers.filter { $0.kind == .bankAccount }
                if !accounts.isEmpty {
                    Menu("Accounts") {
                        ForEach(accounts) { account in
                            Button(action: {
                                viewModel.selectedTarget = .ledger(account.id)
                            }) {
                                if case let .ledger(id) = viewModel.selectedTarget, id == account.id {
                                    Label(account.displayName, systemImage: "checkmark")
                                } else {
                                    Text(account.displayName)
                                }
                            }
                        }
                    }
                }
                Button(action: { initializeCreateSheet(isCard: false) }) {
                    Text("Create New Account...")
                }

                let cards = viewModel.ledgers.filter { $0.kind == .creditCard }
                if !cards.isEmpty {
                    Menu("Cards") {
                        ForEach(cards) { card in
                            Button(action: {
                                viewModel.selectedTarget = .ledger(card.id)
                            }) {
                                if case let .ledger(id) = viewModel.selectedTarget, id == card.id {
                                    Label(card.displayName, systemImage: "checkmark")
                                } else {
                                    Text(card.displayName)
                                }
                            }
                        }
                    }
                }
                Button(action: { initializeCreateSheet(isCard: true) }) {
                    Text("Create New Card...")
                }
            } label: {
                let displayText: String = {
                    if let target = viewModel.selectedTarget {
                        if case let .ledger(id) = target {
                            return viewModel.ledgers.first { $0.id == id }?.displayName ?? "Ledger"
                        }
                    }
                    return "Select Account or Card..."
                }()

                HStack {
                    Text(displayText)
                    Spacer()
                    Image(systemName: "chevron.down")
                }
            }
        }
    }

    func initializeCreateSheet(isCard: Bool) {
        guard let statement = viewModel.importSession.parsedStatements.first else {
            var state = TargetCreationState()
            state.isCard = isCard
            viewModel.importSession.targetBeingCreated = state
            return
        }

        var state = TargetCreationState()
        state.isCard = isCard
        state.initializeFromStatement(statement)

        let detected = statement.bankName.isEmpty ? "Unknown" : statement.bankName
        let matchingBankCase = Banks.allCases.first { bankCase in
            ImportFormatting.fuzzyMatch(bankCase.displayName, detected)
        }
        state.selectedBank = matchingBankCase

        viewModel.importSession.targetBeingCreated = state
    }

    func fileListSection() -> some View {
        ImportFileListView(fileStatementPairs: viewModel.fileStatementPairs)
    }

    func aggregatedSummarySection() -> some View {
        ImportPreviewCard(parsedStatements: viewModel.parsedStatements)
    }

    func aggregatedTransactionListSection() -> some View {
        let allTransactions = viewModel.parsedStatements.flatMap(\.transactions)
        return ImportTransactionListView(
            transactions: allTransactions,
            duplicateIndices: viewModel.duplicateTransactionIndices
        )
    }
}
