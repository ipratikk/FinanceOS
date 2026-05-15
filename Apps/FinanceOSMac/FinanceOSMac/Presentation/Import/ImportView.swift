import FinanceCore
import SwiftUI
import UniformTypeIdentifiers

enum TargetChoice: Hashable {
    case account(UUID)
    case card(UUID)
    case createAccount
    case createCard
}

struct ImportView: View {
    let viewModel: ImportViewModel

    @State private var targetChoice: TargetChoice?
    @State private var isTargeted = false

    var body: some View {
        Group {
            if viewModel.parsedStatements.isEmpty {
                fileSelectionView
            } else {
                previewView
            }
        }
        .onAppear {
            Task {
                await viewModel.loadTargetsOnAppear()
            }

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
            case .createAccount, .createCard, nil:
                break
            }
        }
        .onChange(of: viewModel.selectedTarget) { _, newValue in
            switch newValue {
            case let .account(id):
                targetChoice = .account(id)
            case let .card(id):
                targetChoice = .card(id)
            case nil:
                targetChoice = nil
            }
        }
    }

    private var fileSelectionView: some View {
        ZStack {
            VStack(spacing: 0) {
                if isTargeted {
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)

                        VStack(spacing: 4) {
                            Text("Drop Files Here")
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("CSV, XLS, or XLSX files")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.blue.opacity(0.05))
                } else {
                    ScrollView {
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

                            supportedSourcesView

                            Divider()

                            if viewModel.isLoading {
                                ProgressView("Parsing files...")
                            } else {
                                dropZoneView

                                Divider()

                                filePickerButton
                            }

                            if !viewModel.parsedStatements.isEmpty {
                                Divider()

                                targetSelectionSection
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
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
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            VStack(spacing: 4) {
                Text("Drag files here or click button below")
                    .font(.headline)

                Text("CSV or XLSX formats supported")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
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

            if panel.runModal() == .OK, !panel.urls.isEmpty {
                viewModel.setFileURLs(panel.urls)
                viewModel.parseFiles()
            }
        }
        .controlSize(.large)
    }

    private var previewView: some View {
        VStack(spacing: 0) {
            if !viewModel.parsedStatements.isEmpty {
                ImportPreviewView(viewModel: viewModel, targetChoice: $targetChoice)
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

    private var supportedSourcesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Supported Statements")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(viewModel.supportedSources.enumerated()), id: \.offset) { _, source in
                    let isFullySupported = source.bankName == "ICICI" && source.sourceType == .bankAccount
                    let status = isFullySupported ? "" : " (coming soon)"
                    Text("• \(source.bankName) \(source.sourceType.rawValue)\(status)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("💡 Use CSV or XLSX for best results.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("PDF and delimited text support coming soon.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(4)
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
                        Text(account.accountName)
                            .tag(TargetChoice.account(account.id) as TargetChoice?)
                    }
                }

                if !viewModel.cards.isEmpty {
                    Divider()
                    Text("Cards").font(.caption).tag(nil as TargetChoice?)

                    ForEach(viewModel.cards) { card in
                        Text(card.cardName)
                            .tag(TargetChoice.card(card.id) as TargetChoice?)
                    }
                }
            }
        }
    }
}

#Preview {
    let mockImporter = MockTransactionImporter()
    let mockRepository = MockTransactionRepository()
    let mockRegistry = StatementParserRegistry(
        parsers: [
            ICICIBankStatementParser(),
            ICICICardStatementParser(),
            HDFCBankStatementParser(),
            HDFCCardStatementParser(),
            AmexCardStatementParser()
        ]
    )
    let mockPipeline = TransactionImportPipeline(
        importer: mockImporter,
        repository: mockRepository
    )

    ImportView(
        viewModel: ImportViewModel(
            transactionImporter: mockImporter,
            transactionImportPipeline: mockPipeline,
            bankRepository: MockBankRepository(),
            accountRepository: MockAccountRepository(),
            cardRepository: MockCardRepository(),
            transactionRepository: mockRepository,
            parserRegistry: mockRegistry
        )
    )
}
