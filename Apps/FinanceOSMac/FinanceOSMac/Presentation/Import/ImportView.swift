import FinanceCore
import FinanceParsers
import FinanceUI
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
                            FDSLabel("Drop Files Here", style: .heading)

                            FDSLabel("Release to import", style: .hint)
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
                                        Text(
                                            "Parsing file \(viewModel.currentFileIndex + 1) of \(viewModel.totalFilesToParse)..."
                                        )
                                        .labelSmall()
                                        .foregroundColor(AppColors.textTertiary)
                                    } else {
                                        FDSLabel("Parsing statement...", style: .hint)
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
        VStack(alignment: .leading, spacing: AppSpacing.tight) {
            Text("IMPORT")
                .captionSmall()
                .tracking(0.6)
                .foregroundStyle(.tertiary)
            Text("Statements")
                .displayMedium()
            Text("Upload bank or credit card statements")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var filePickerButton: some View {
        FDSLiquidButton("Select Files", symbol: "folder.badge.plus", variant: .primary) {
            let panel = NSOpenPanel()
            let allowedFormats = selectedSource?.allowedFormats ?? []
            panel.allowedContentTypes = allowedFormats.map(\.utType)
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = true

            if panel.runModal() == .OK, !panel.urls.isEmpty {
                viewModel.setFileURLs(panel.urls)
                viewModel.parseFiles()
            }
        }
        .disabled(selectedSource == nil)
        .frame(maxWidth: .infinity)
    }

    private func importSuccessBanner(result: ImportResult) -> some View {
        HStack(spacing: AppSpacing.compact) {
            Image(systemName: "checkmark.circle.fill")
                .bodyMedium()
                .foregroundStyle(AppColors.credit)
            Text("Imported \(result.inserted) transaction\(result.inserted == 1 ? "" : "s")" +
                (result.skipped > 0 ? " · \(result.skipped) skipped" : ""))
                .bodySmall()
                .foregroundStyle(.primary)
            Spacer()
            Button(action: { viewModel.lastImportResult = nil }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.compact)
        .background {
            Capsule(style: .continuous)
                .fill(.thickMaterial)
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(AppColors.credit.opacity(0.3), lineWidth: 0.5)
                }
        }
        .padding(AppSpacing.md)
    }

    private var previewView: some View {
        VStack(spacing: 0) {
            if !viewModel.parsedStatements.isEmpty {
                ImportPreviewView(viewModel: viewModel)
            }

            Divider().opacity(0.3)

            HStack(spacing: AppSpacing.compact) {
                FDSLiquidButton("Cancel", variant: .subtle) {
                    viewModel.fileURLs = []
                    viewModel.parsedStatements = []
                    viewModel.selectedTarget = nil
                }
                Spacer()
                FDSLiquidButton(
                    "Import",
                    symbol: "arrow.down.doc.fill",
                    variant: .primary
                ) {
                    viewModel.importTransactions()
                }
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
