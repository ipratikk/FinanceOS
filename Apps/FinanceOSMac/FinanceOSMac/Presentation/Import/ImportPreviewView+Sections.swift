import FinanceCore
import FinanceParsers
import SwiftUI

extension ImportPreviewView {
    var targetSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Import To")
                .font(.headline)

            Picker("Target", selection: $targetChoice) {
                Text("Select Account or Card...").tag(nil as TargetChoice?)

                if !viewModel.accounts.isEmpty {
                    Divider()
                    Text("Accounts").font(.caption).tag(nil as TargetChoice?)

                    ForEach(viewModel.accounts) { account in
                        Text(account.accountName)
                            .tag(TargetChoice.account(account.id) as TargetChoice?)
                    }

                    Text("Create New Account...")
                        .tag(TargetChoice.createAccount as TargetChoice?)
                }

                if !viewModel.cards.isEmpty {
                    Divider()
                    Text("Cards").font(.caption).tag(nil as TargetChoice?)

                    ForEach(viewModel.cards) { card in
                        Text(card.cardName)
                            .tag(TargetChoice.card(card.id) as TargetChoice?)
                    }

                    Text("Create New Card...")
                        .tag(TargetChoice.createCard as TargetChoice?)
                }

                if viewModel.accounts.isEmpty {
                    Divider()
                    Text("Create New Account...")
                        .tag(TargetChoice.createAccount as TargetChoice?)
                }

                if viewModel.cards.isEmpty {
                    if !viewModel.accounts.isEmpty {
                        Divider()
                    }
                    Text("Create New Card...")
                        .tag(TargetChoice.createCard as TargetChoice?)
                }
            }
            .onChange(of: targetChoice) { _, newValue in
                handleTargetSelection(newValue)
            }
        }
    }

    func handleTargetSelection(_ choice: TargetChoice?) {
        switch choice {
        case .createAccount:
            initializeCreateSheet(isCard: false)
        case .createCard:
            initializeCreateSheet(isCard: true)
        case .account, .card, .none:
            break
        }
    }

    func initializeCreateSheet(isCard: Bool) {
        let detected = viewModel.parsedStatements.first?.bankName ?? "Unknown"
        let metadata = viewModel.parsedStatements.first?.metadata
        detectedBank = detected
        self.isCard = isCard

        if isCard, let cardLast4 = viewModel.parsedStatements.first?.cardLast4 {
            let nameConstructed = "\(detected) •••• \(cardLast4)"
            newEntityName = nameConstructed
            newEntityNickname = ""
            newEntityLast4 = cardLast4
            newEntityOwnerName = ""
        } else {
            let accountLast4 = viewModel.parsedStatements.first?.accountLast4 ?? ""
            let nameConstructed = !accountLast4.isEmpty ? "\(detected) •••• \(accountLast4)" : detected
            newEntityName = nameConstructed
            newEntityNickname = ""
            newEntityLast4 = accountLast4
            newEntityOwnerName = metadata?.customerName ?? ""
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
