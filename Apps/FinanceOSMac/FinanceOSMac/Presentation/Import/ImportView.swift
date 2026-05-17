import FinanceCore
import FinanceParsers
import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    let viewModel: ImportViewModel

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
        .overlay(alignment: .top) {
            if let result = viewModel.lastImportResult {
                importSuccessBanner(result: result)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.lastImportResult != nil)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadTargetsOnAppear()
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
                            .font(.system(size: 48, weight: .semibold))
                            .foregroundColor(AppColors.accent)

                        VStack(spacing: 4) {
                            Text("Drop Files Here")
                                .headingSmall()

                            Text("Release to import")
                                .labelSmall()
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.accent.opacity(0.1))
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            headerSection

                            SourcePickerSection(
                                selectedSource: $selectedSource,
                                errorMessage: viewModel.errorMessage
                            )

                            if viewModel.isLoading {
                                VStack(spacing: 8) {
                                    ProgressView()
                                        .controlSize(.small)

                                    if viewModel.totalFilesToParse > 1 {
                                        Text("Parsing file \(viewModel.currentFileIndex + 1) of \(viewModel.totalFilesToParse)...")
                                            .labelSmall()
                                            .foregroundColor(AppColors.textTertiary)
                                    } else {
                                        Text("Parsing statement...")
                                            .labelSmall()
                                            .foregroundColor(AppColors.textTertiary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(AppSpacing.lg)
                                .background(AppColors.surface)
                                .cornerRadius(AppRadius.md)
                            } else {
                                if selectedSource != nil {
                                    DropZoneView(selectedSource: selectedSource)
                                    filePickerButton
                                } else {
                                    FileSelectionPlaceholder()
                                }
                            }

                            if !viewModel.parsedStatements.isEmpty {
                                TargetSelectionSection(viewModel: viewModel)
                            }

                            Spacer()
                                .frame(height: 20)
                        }
                        .padding(AppSpacing.md)
                    }
                }
            }
            .background(AppColors.base)
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

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Import Statements")
                .headingMedium()

            Text("Upload your bank or credit card statements")
                .caption()
                .foregroundColor(AppColors.textTertiary)
        }
    }

    private var filePickerButton: some View {
        Button(action: {
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

            if result == .OK, !panel.urls.isEmpty {
                viewModel.setFileURLs(panel.urls)
                viewModel.parseFiles()
            }
        }, label: {
            HStack(spacing: 8) {
                Image(systemName: "folder.badge.plus")
                    .monoAmount()

                Text("Select Files")
                    .bodyLarge()
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.sm)
            .foregroundColor(.white)
        })
        .background(AppColors.accent)
        .cornerRadius(AppRadius.md)
        .disabled(selectedSource == nil)
    }

    private func importSuccessBanner(result: ImportResult) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
            Text("Imported \(result.inserted) transaction\(result.inserted == 1 ? "" : "s")" +
                (result.skipped > 0 ? " (\(result.skipped) skipped)" : ""))
                .bodyLarge()
                .foregroundColor(.white)
            Spacer()
            Button(action: { viewModel.lastImportResult = nil }, label: {
                Image(systemName: "xmark")
                    .labelSmall()
                    .foregroundColor(.white.opacity(0.8))
            })
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.sm)
        .background(AppColors.credit.opacity(0.85))
        .cornerRadius(AppRadius.md)
        .padding(AppSpacing.md)
        .shadow(radius: 4)
    }

    private var previewView: some View {
        VStack(spacing: 0) {
            if !viewModel.parsedStatements.isEmpty {
                ImportPreviewView(viewModel: viewModel)
            }

            Divider()

            HStack(spacing: 12) {
                Button(action: {
                    viewModel.fileURLs = []
                    viewModel.parsedStatements = []
                    viewModel.selectedTarget = nil
                }, label: {
                    Text("Cancel")
                        .bodyLarge()
                        .frame(maxWidth: .infinity)
                })
                .foregroundColor(.gray)
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .cornerRadius(AppRadius.md)

                Button(action: viewModel.importTransactions, label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.doc.fill")
                            .monoAmount()

                        Text("Import")
                            .monoAmount()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                })
                .padding(AppSpacing.sm)
                .background(AppColors.accent)
                .cornerRadius(AppRadius.md)
                .disabled(viewModel.selectedTarget == nil || viewModel.isLoading)
                .keyboardShortcut(.defaultAction)
            }
            .padding(AppSpacing.md)
        }
    }
}

#Preview {
    let mockRepository = MockTransactionRepository()
    let mockPipeline = TransactionImportPipeline(
        repository: mockRepository
    )

    ImportView(
        viewModel: ImportViewModel(
            transactionImportPipeline: mockPipeline,
            bankRepository: MockBankRepository(),
            ledgerRepository: MockLedgerRepository(),
            transactionRepository: mockRepository
        )
    )
}
