import FinanceCore
import FinanceParsers
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
    @State private var showPasswordPrompt = false
    @State private var passwordPromptFilename = ""

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

                            Text("CSV, TXT, XLSX, or PDF files")
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

                            SupportedSourcesView(viewModel: viewModel)

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

                                TargetSelectionSection(viewModel: viewModel, targetChoice: $targetChoice)
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
        .onChange(of: viewModel.passwordPromptFilename) { _, newValue in
            if newValue != nil {
                viewModel.isPasswordInvalid = false
                showPasswordPrompt = true
                passwordPromptFilename = newValue ?? ""
            }
        }
        .sheet(isPresented: $showPasswordPrompt) {
            PasswordPromptSheet(
                filename: passwordPromptFilename,
                isPasswordInvalid: viewModel.isPasswordInvalid,
                onCancel: {
                    showPasswordPrompt = false
                    viewModel.passwordPromptFilename = nil
                    viewModel.isPasswordInvalid = false
                    viewModel.fileURLs = []
                    viewModel.errorMessage = nil
                },
                onSubmit: { password, saveToKeychain in
                    viewModel.isPasswordInvalid = false
                    Task {
                        await viewModel.retryParseFilesWithPassword(password, saveToKeychain: saveToKeychain)
                    }
                }
            )
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

                Text("CSV, TXT, XLSX, or PDF formats supported")
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
            print("[UI] Select Files button tapped")
            let panel = NSOpenPanel()
            var types: [UTType] = [.commaSeparatedText, .plainText, .pdf]
            if let xlsx = UTType(filenameExtension: "xlsx") {
                types.append(xlsx)
            }
            panel.allowedContentTypes = types
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = true

            let result = panel.runModal()
            print("[UI] Panel result: \(result.rawValue), urls: \(panel.urls.count)")

            if result == .OK, !panel.urls.isEmpty {
                print("[UI] Conditions met, calling setFileURLs and parseFiles")
                viewModel.setFileURLs(panel.urls)
                viewModel.parseFiles()
            } else {
                print("[UI] Conditions not met - result=\(result.rawValue) isEmpty=\(panel.urls.isEmpty)")
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
