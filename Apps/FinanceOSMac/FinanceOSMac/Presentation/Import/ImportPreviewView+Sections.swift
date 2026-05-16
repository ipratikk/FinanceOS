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
