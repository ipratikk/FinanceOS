import FinanceCore
import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    let viewModel: ImportViewModel

    /// Local, Hashable selection type for Picker to avoid requiring TransactionImportTarget to be Hashable
    private enum TargetChoice: Hashable {
        case account(UUID)
        case card(UUID)
    }

    @State private var targetChoice: TargetChoice? = nil

    var body: some View {
        Group {
            if viewModel.parsedStatement == nil {
                fileSelectionView
            } else {
                previewView
            }
        }
        .onAppear {
            if let target = viewModel.selectedTarget {
                switch target {
                case let .account(id):
                    targetChoice = .account(id)
                case let .card(id):
                    targetChoice = .card(id)
                }
            } else {
                targetChoice = nil
            }
        }
        .onChange(of: targetChoice) { _, newValue in
            switch newValue {
            case let .account(id):
                viewModel.selectedTarget = .account(id)
            case let .card(id):
                viewModel.selectedTarget = .card(id)
            case nil:
                viewModel.selectedTarget = nil
            }
        }
    }

    private var fileSelectionView: some View {
        VStack(spacing: 16) {
            if let error = viewModel.errorMessage {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Error")
                        .font(.caption)
                        .fontWeight(.semibold)

                    Text(error)
                        .font(.caption)
                        .lineLimit(5)
                }
                .foregroundColor(.red)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(4)
            }

            if viewModel.isLoading {
                ProgressView("Parsing file...")
            } else {
                dropZoneView

                Divider()

                filePickerButton
            }
        }
        .padding()
    }

    private var dropZoneView: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("Drag CSV or XLSX file here")
                .font(.headline)

            Text("Or click to browse")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url {
                        DispatchQueue.main.async {
                            viewModel.setFileURL(url)
                            viewModel.parseFile()
                        }
                    }
                }
            }
            return true
        }
    }

    private var filePickerButton: some View {
        Button("Select File") {
            let panel = NSOpenPanel()
            var types: [UTType] = [.commaSeparatedText]
            if let xlsx = UTType(filenameExtension: "xlsx") {
                types.append(xlsx)
            }
            panel.allowedContentTypes = types
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = false

            if panel.runModal() == .OK,
               let url = panel.url
            {
                viewModel.setFileURL(url)
                viewModel.parseFile()
            }
        }
        .controlSize(.large)
    }

    private var previewView: some View {
        VStack(spacing: 0) {
            if let statement = viewModel.parsedStatement {
                importPreviewView(statement)
            }

            Divider()

            HStack(spacing: 12) {
                Button("Cancel") {
                    viewModel.fileURL = nil
                    viewModel.parsedStatement = nil
                    viewModel.selectedTarget = nil
                }

                Spacer()

                Button("Import", action: viewModel.importTransactions)
                    .disabled(viewModel.selectedTarget == nil || viewModel.isLoading)
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
    }

    private func importPreviewView(
        _ statement: ParsedStatement
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                statementHeaderSection(statement)

                Divider()

                summarySection(statement)

                Divider()

                targetSelectionSection

                Divider()

                transactionListSection(statement)
            }
            .padding()
        }
    }

    private func statementHeaderSection(
        _ statement: ParsedStatement
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(statement.institution)
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(statement.accountName)
                        .font(.subheadline)

                    if let last4 = statement.cardLast4 {
                        Text("Card ending in \(last4)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text("INR")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func summarySection(
        _ statement: ParsedStatement
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Statement Summary")
                .font(.headline)

            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Period")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let start = statement.statementPeriodStart,
                       let end = statement.statementPeriodEnd
                    {
                        Text("\(formatDate(start)) - \(formatDate(end))")
                            .font(.body)
                    } else {
                        Text("—")
                            .font(.body)
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Total Transactions")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(statement.transactions.count)")
                        .font(.body)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Debits")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(formatAmount(statement.totalDebit))
                        .font(.body)
                        .foregroundColor(.red)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Credits")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(formatAmount(statement.totalCredit))
                        .font(.body)
                        .foregroundColor(.green)
                }
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

    private func transactionListSection(
        _ statement: ParsedStatement
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transactions (\(statement.transactions.count))")
                .font(.headline)

            VStack(spacing: 4) {
                let firstFive = Array(statement.transactions.prefix(5))
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

                    if index < min(4, statement.transactions.count - 1) {
                        Divider()
                    }
                }
            }
            .padding(.vertical, 8)

            if statement.transactions.count > 5 {
                Text(
                    "... and \(statement.transactions.count - 5) more transactions"
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

#Preview {
    ImportView(
        viewModel: ImportViewModel(
            transactionImporter: DefaultTransactionImporter(),
            transactionRepository: MockTransactionRepository(),
            accountRepository: MockAccountRepository(),
            cardRepository: MockCardRepository()
        )
    )
}

private struct MockTransactionRepository: TransactionRepository {
    func fetchTransactionsForAccount(_ accountID: UUID) async throws -> [FinanceCore.Transaction] {
        []
    }

    func fetchTransactionsForCard(_ cardID: UUID) async throws -> [FinanceCore.Transaction] {
        []
    }

    func fetchTransactions() async throws -> [FinanceCore.Transaction] {
        []
    }

    func insertTransactions(_ transactions: [FinanceCore.Transaction]) async throws {}
}

private struct MockAccountRepository: AccountRepository {
    func fetchAccounts() async throws -> [Account] {
        []
    }
}

private struct MockCardRepository: CardRepository {
    func fetchCards() async throws -> [Card] {
        []
    }
}
