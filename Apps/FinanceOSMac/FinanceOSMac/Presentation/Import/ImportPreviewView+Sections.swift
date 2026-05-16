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

                if !viewModel.accounts.isEmpty {
                    Menu("Accounts") {
                        ForEach(viewModel.accounts) { account in
                            Button(action: {
                                viewModel.selectedTarget = .account(account.id)
                            }) {
                                if case .account(let id) = viewModel.selectedTarget, id == account.id {
                                    Label(account.accountName, systemImage: "checkmark")
                                } else {
                                    Text(account.accountName)
                                }
                            }
                        }
                    }
                    Button(action: { initializeCreateSheet(isCard: false) }) {
                        Text("Create New Account...")
                    }
                }

                if !viewModel.cards.isEmpty {
                    Menu("Cards") {
                        ForEach(viewModel.cards) { card in
                            Button(action: {
                                viewModel.selectedTarget = .card(card.id)
                            }) {
                                if case .card(let id) = viewModel.selectedTarget, id == card.id {
                                    Label(card.cardName, systemImage: "checkmark")
                                } else {
                                    Text(card.cardName)
                                }
                            }
                        }
                    }
                    Button(action: { initializeCreateSheet(isCard: true) }) {
                        Text("Create New Card...")
                    }
                }

                if viewModel.accounts.isEmpty && viewModel.cards.isEmpty {
                    Button(action: { initializeCreateSheet(isCard: false) }) {
                        Text("Create New Account...")
                    }
                    Button(action: { initializeCreateSheet(isCard: true) }) {
                        Text("Create New Card...")
                    }
                }
            } label: {
                let displayText: String = {
                    if let target = viewModel.selectedTarget {
                        switch target {
                        case .account(let id):
                            return viewModel.accounts.first { $0.id == id }?.accountName ?? "Account"
                        case .card(let id):
                            return viewModel.cards.first { $0.id == id }?.cardName ?? "Card"
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
        guard let statement = viewModel.parsedStatements.first else {
            detectedBank = "Unknown"
            self.isCard = isCard
            newEntityName = ""
            newEntityOwnerName = ""
            newEntityLast4 = ""
            showCreateSheet = true
            return
        }

        let detected = statement.bankName.isEmpty ? "Unknown" : statement.bankName
        detectedBank = detected
        self.isCard = isCard

        if isCard {
            let cardLast4 = statement.cardLast4 ?? ""
            let nameConstructed = !cardLast4.isEmpty
                ? "\(detected) •••• \(cardLast4)"
                : detected
            newEntityName = nameConstructed
            newEntityNickname = ""
            newEntityLast4 = cardLast4
            newEntityOwnerName = ""
        } else {
            let accountLast4 = statement.accountLast4 ?? ""
            let displayName = statement.accountName.isEmpty ? detected : statement.accountName
            let nameConstructed = !accountLast4.isEmpty
                ? "\(displayName) •••• \(accountLast4)"
                : displayName
            newEntityName = nameConstructed
            newEntityNickname = ""
            newEntityLast4 = accountLast4
            newEntityOwnerName = statement.metadata?.customerName ?? ""
        }

        let matchingBank = viewModel.banks.first { bank in
            ImportFormatting.fuzzyMatch(bank.name, detected)
        }
        newEntityBankID = matchingBank?.id
        showCreateSheet = true
        targetChoice = nil
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
