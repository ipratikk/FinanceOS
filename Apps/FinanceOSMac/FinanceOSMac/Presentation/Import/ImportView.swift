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
            if viewModel.parsedStatements.isEmpty {
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
                ProgressView("Parsing files...")
            } else {
                dropZoneView

                Divider()

                filePickerButton
            }
        }
        .padding()
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            var urls: [URL] = []
            let group = DispatchGroup()

            for provider in providers {
                group.enter()
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url {
                        urls.append(url)
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                if !urls.isEmpty {
                    viewModel.setFileURLs(urls)
                    viewModel.parseFiles()
                }
            }
            return true
        }
    }

    private var dropZoneView: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("Drag CSV or XLSX files here")
                .font(.headline)

            Text("Or click to browse")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    private var filePickerButton: some View {
        Button("Select Files") {
            let panel = NSOpenPanel()
            var types: [UTType] = [.commaSeparatedText]
            if let xlsx = UTType(filenameExtension: "xlsx") {
                types.append(xlsx)
            }
            panel.allowedContentTypes = types
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = true

            if panel.runModal() == .OK,
               !panel.urls.isEmpty
            {
                viewModel.setFileURLs(panel.urls)
                viewModel.parseFiles()
            }
        }
        .controlSize(.large)
    }

    private var previewView: some View {
        VStack(spacing: 0) {
            if !viewModel.parsedStatements.isEmpty {
                importPreviewView()
            }

            Divider()

            HStack(spacing: 12) {
                Button("Cancel") {
                    viewModel.fileURLs = []
                    viewModel.parsedStatements = []
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

    private func importPreviewView() -> some View {
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
    }

    private func fileListSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Files")
                .font(.headline)

            VStack(spacing: 4) {
                ForEach(viewModel.fileStatementPairs.indices, id: \.self) { index in
                    let pair = viewModel.fileStatementPairs[index]
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

                    if index < viewModel.fileStatementPairs.count - 1 {
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

        return VStack(alignment: .leading, spacing: 8) {
            Text("Transactions (\(allTransactions.count))")
                .font(.headline)

            VStack(spacing: 4) {
                let firstFive = Array(allTransactions.prefix(5))
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

                    if index < min(4, allTransactions.count - 1) {
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
