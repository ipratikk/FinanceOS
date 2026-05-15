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
    @State private var selectedSource: StatementSource?
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
        .onChange(of: selectedSource) { _, newValue in
            viewModel.setSource(newValue)
        }
        .onChange(of: viewModel.selectedSource) { _, newValue in
            selectedSource = newValue
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

                            Text("CSV or delimited TXT files")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.blue.opacity(0.05))
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            SourcePickerSection(selectedSource: $selectedSource, errorMessage: viewModel.errorMessage)

                            Divider()

                            if viewModel.isLoading {
                                ProgressView("Parsing files...")
                            } else {
                                if selectedSource != nil {
                                    DropZoneView(selectedSource: selectedSource)
                                    Divider()
                                    filePickerButton
                                } else {
                                    FileSelectionPlaceholder()
                                }
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
            guard let source = selectedSource else { return false }

            var urls: [URL] = []
            let group = DispatchGroup()

            for provider in providers {
                group.enter()
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url {
                        let ext = url.pathExtension.lowercased()
                        let allowedExts = source.allowedFormats.map(\.rawValue)
                        if allowedExts.contains(ext) {
                            urls.append(url)
                        }
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

    private var filePickerButton: some View {
        Button("Select Files") {
            print("[UI] Select Files button tapped")
            let panel = NSOpenPanel()

            let allowedFormats = selectedSource?.allowedFormats ?? []
            var types: [UTType] = []
            for format in allowedFormats {
                types.append(format.utType)
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
        .disabled(selectedSource == nil)
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
