import FinanceCore
import SwiftUI

struct ImportPreviewView: View {
    let viewModel: ImportViewModel
    @Binding var targetChoice: TargetChoice?

    @State private var showCreateSheet = false
    @State private var newEntityName = ""
    @State private var newEntityInstitutionID: UUID?
    @State private var isCard = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                fileListSection()

                Divider()

                aggregatedSummarySection()

                Divider()

                detectedTargetSection()

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
                institutionID: $newEntityInstitutionID,
                isCard: isCard,
                institutions: viewModel.institutions,
                onCancel: {
                    showCreateSheet = false
                },
                onCreate: {
                    Task {
                        await viewModel.createTargetFromDetected(
                            customName: newEntityName,
                            institutionID: newEntityInstitutionID,
                            isCard: isCard
                        )
                        showCreateSheet = false
                    }
                }
            )
        }
    }

    private func detectedTargetSection() -> some View {
        let detectedInstitution = viewModel.parsedStatements.first?.institution ?? "Unknown"
        let isCard = viewModel.parsedStatements.first?.cardLast4 != nil

        return VStack(alignment: .leading, spacing: 12) {
            Text("Detected Target")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Institution:")
                        .fontWeight(.semibold)
                    Text(detectedInstitution)
                        .foregroundColor(.secondary)
                }

                if isCard {
                    if let cardLast4 = viewModel.parsedStatements.first?.cardLast4 {
                        HStack {
                            Text("Card Last 4:")
                                .fontWeight(.semibold)
                            Text(cardLast4)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    if let accountName = viewModel.parsedStatements.first?.accountName {
                        HStack {
                            Text("Account:")
                                .fontWeight(.semibold)
                            Text(accountName)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 8)

            HStack(spacing: 12) {
                Button("Create as New") {
                    let isCardTarget = viewModel.parsedStatements.first?.cardLast4 != nil
                    self.isCard = isCardTarget

                    if isCardTarget, let cardLast4 = viewModel.parsedStatements.first?.cardLast4 {
                        self.newEntityName = "\(detectedInstitution) Card - \(cardLast4)"
                    } else {
                        let accountName = viewModel.parsedStatements.first?.accountName ?? ""
                        self.newEntityName = accountName.isEmpty ? "\(detectedInstitution) Account" : accountName
                    }

                    self.newEntityInstitutionID = nil
                    self.showCreateSheet = true
                }
                .buttonStyle(.bordered)

                Spacer()

                Text("or select below →")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
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
                }

                if !viewModel.cards.isEmpty {
                    Divider()
                    Text("Cards").font(.caption).tag(nil as TargetChoice?)

                    ForEach(viewModel.cards) { card in
                        Text(card.name)
                            .tag(TargetChoice.card(card.id) as TargetChoice?)
                    }
                }
            }
        }
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
        let firstFive = Array(allTransactions.prefix(5))

        return VStack(alignment: .leading, spacing: 8) {
            Text("Transactions (\(allTransactions.count))")
                .font(.headline)

            VStack(spacing: 4) {
                ForEach(firstFive.indices, id: \.self) { index in
                    let txn = firstFive[index]
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(txn.description)
                                .font(.body)
                                .lineLimit(1)

                            HStack(spacing: 8) {
                                Text(formatDate(txn.postedAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)

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
