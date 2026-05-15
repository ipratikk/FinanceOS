import FinanceCore
import SwiftUI

struct ImportPreviewView: View {
    let viewModel: ImportViewModel
    @Binding var targetChoice: TargetChoice?

    @State private var showCreateSheet = false
    @State private var newEntityName = ""
    @State private var newEntityNickname = ""
    @State private var newEntityLast4 = ""
    @State private var newEntityInstitutionID: UUID?
    @State private var detectedInstitution = ""
    @State private var isCard = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                fileListSection()

                Divider()

                aggregatedSummarySection()

                Divider()

                targetSelectionSection

                Divider()

                aggregatedTransactionListSection()
            }
            .padding()
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateNewTargetSheet(
                name: $newEntityName,
                nickname: $newEntityNickname,
                last4: $newEntityLast4,
                institutionID: $newEntityInstitutionID,
                isCard: isCard,
                institutions: viewModel.institutions,
                detectedInstitution: detectedInstitution,
                onCancel: {
                    showCreateSheet = false
                },
                onCreate: {
                    Task {
                        await viewModel.createTargetFromDetected(
                            customName: newEntityName,
                            nickname: newEntityNickname,
                            last4: newEntityLast4,
                            institutionID: newEntityInstitutionID,
                            isCard: isCard
                        )
                        showCreateSheet = false
                    }
                }
            )
        }
    }

    private var targetSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Import To")
                .font(.headline)

            Picker("Target", selection: $targetChoice) {
                Text("Select Account or Card...").tag(nil as TargetChoice?)

                if !viewModel.accounts.isEmpty {
                    Divider()
                    Text("Accounts").font(.caption).tag(nil as TargetChoice?)

                    ForEach(viewModel.accounts) { account in
                        Text(account.name)
                            .tag(TargetChoice.account(account.id) as TargetChoice?)
                    }

                    Text("Create New Account...")
                        .tag(TargetChoice.createAccount as TargetChoice?)
                }

                if !viewModel.cards.isEmpty {
                    Divider()
                    Text("Cards").font(.caption).tag(nil as TargetChoice?)

                    ForEach(viewModel.cards) { card in
                        Text(card.name)
                            .tag(TargetChoice.card(card.id) as TargetChoice?)
                    }

                    Text("Create New Card...")
                        .tag(TargetChoice.createCard as TargetChoice?)
                }

                if viewModel.accounts.isEmpty, viewModel.cards.isEmpty {
                    Divider()
                    Text("Create New Account...")
                        .tag(TargetChoice.createAccount as TargetChoice?)
                    Text("Create New Card...")
                        .tag(TargetChoice.createCard as TargetChoice?)
                }
            }
            .onChange(of: targetChoice) { _, newValue in
                handleTargetSelection(newValue)
            }
        }
    }

    private func handleTargetSelection(_ choice: TargetChoice?) {
        switch choice {
        case .createAccount:
            initializeCreateSheet(isCard: false)
        case .createCard:
            initializeCreateSheet(isCard: true)
        case .account, .card, .none:
            break
        }
    }

    private func initializeCreateSheet(isCard: Bool) {
        let detected = viewModel.parsedStatements.first?.institution ?? "Unknown"
        detectedInstitution = detected
        self.isCard = isCard

        if isCard, let cardLast4 = viewModel.parsedStatements.first?.cardLast4 {
            newEntityName = "\(detected) Card"
            newEntityNickname = ""
            newEntityLast4 = cardLast4
        } else {
            let accountName = viewModel.parsedStatements.first?.accountName ?? ""
            newEntityName = accountName.isEmpty ? "\(detected) Account" : accountName
            newEntityNickname = ""
            newEntityLast4 = ""
        }

        let matchingInstitution = viewModel.institutions.first { inst in
            fuzzyMatch(inst.name, detected)
        }
        newEntityInstitutionID = matchingInstitution?.id
        showCreateSheet = true
        targetChoice = nil
    }

    private func fuzzyMatch(_ stored: String, _ parsed: String) -> Bool {
        let storedLower = stored.lowercased()
        let parsedLower = parsed.lowercased()

        if storedLower == parsedLower { return true }
        if storedLower.contains(parsedLower) || parsedLower.contains(storedLower) { return true }

        let storedWords = storedLower.split(separator: " ").map(String.init)
        let parsedWords = parsedLower.split(separator: " ").map(String.init)

        let commonWords = Set(storedWords).intersection(Set(parsedWords))
        return !commonWords.isEmpty && commonWords.count >= min(storedWords.count, parsedWords.count) / 2
    }

    private func fileListSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Files")
                .font(.headline)

            VStack(spacing: 4) {
                let pairs = viewModel.fileStatementPairs
                ForEach(pairs.indices, id: \.self) { index in
                    let pair = pairs[index]
                    HStack {
                        Image(systemName: "doc.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(pair.url.lastPathComponent)
                            .font(.body)
                            .lineLimit(1)

                        Spacer()

                        Text("\(pair.statement.transactions.count) txns")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    if index < pairs.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func aggregatedSummarySection() -> some View {
        let totalTransactions = viewModel.parsedStatements.reduce(0) { $0 + $1.transactions.count }
        let totalDebit = viewModel.parsedStatements.reduce(0) { $0 + $1.totalDebit }
        let totalCredit = viewModel.parsedStatements.reduce(0) { $0 + $1.totalCredit }

        return VStack(alignment: .leading, spacing: 8) {
            Text("Import Summary")
                .font(.headline)

            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Total Files")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(viewModel.parsedStatements.count)")
                        .font(.body)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Total Transactions")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(totalTransactions)")
                        .font(.body)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Total Debits")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(formatAmount(totalDebit))
                        .font(.body)
                        .foregroundColor(.red)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Total Credits")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(formatAmount(totalCredit))
                        .font(.body)
                        .foregroundColor(.green)
                }
            }
        }
    }

    private func aggregatedTransactionListSection() -> some View {
        let allTransactions = viewModel.parsedStatements.flatMap(\.transactions)
        let newTransactions = allTransactions.count - viewModel.duplicateTransactionIndices.count
        let firstFive = Array(allTransactions.prefix(5))

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("New Transactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(newTransactions)")
                        .font(.body)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Already Imported")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.duplicateTransactionIndices.count)")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
            .padding(.vertical, 8)

            Divider()

            Text("Transactions (\(allTransactions.count))")
                .font(.headline)

            VStack(spacing: 4) {
                ForEach(firstFive.indices, id: \.self) { index in
                    let txn = firstFive[index]
                    let isDuplicate = viewModel.duplicateTransactionIndices.contains(index)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(txn.description)
                                .font(.body)
                                .lineLimit(1)
                                .opacity(isDuplicate ? 0.5 : 1.0)

                            HStack(spacing: 8) {
                                Text(formatDate(txn.postedAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                if isDuplicate {
                                    Text("Already imported")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }

                                if let points = txn.rewardPoints, points > 0 {
                                    Text("+\(points) pts")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }

                        Spacer()

                        Text(formatAmount(txn.amountMinorUnits))
                            .font(.body)
                            .foregroundColor(
                                txn.amountMinorUnits < 0 ? .red : .green
                            )
                            .opacity(isDuplicate ? 0.5 : 1.0)
                    }
                    .padding(.vertical, 4)

                    if index < firstFive.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.vertical, 8)

            if allTransactions.count > 5 {
                Text(
                    "... and \(allTransactions.count - 5) more transactions"
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatAmount(_ minorUnits: Int64) -> String {
        let amount = Double(minorUnits) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        return formatter.string(from: NSNumber(value: amount)) ?? "₹\(amount)"
    }
}
