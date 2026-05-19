import AppKit
import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI
import UniformTypeIdentifiers

extension ImportView {
    // MARK: - Step 1: Source Selection

    var sourceStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select a source")
                        .font(AppTypography.headingLg)
                        .foregroundColor(DesignTokens.Text.primary)

                    Text(
                        "Pick the institution and ledger type. Each parser maps " +
                            "statement-specific columns to a normalised transaction."
                    )
                    .font(AppTypography.bodySm)
                    .foregroundColor(DesignTokens.Text.secondary)
                }

                // Source grid
                ImportSourceGrid(
                    sources: StatementSource.allCases,
                    selectedSource: viewModel.selectedSource,
                    onSelectSource: viewModel.selectSourceAndAdvance(_:)
                )

                Spacer()
            }
            .padding(AppSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Step 2: File Upload

    var uploadStep: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Drop your statement")
                        .font(AppTypography.headingMd)
                        .foregroundColor(DesignTokens.Text.primary)

                    if let source = viewModel.selectedSource {
                        let formats = source.allowedFormats.map { $0.rawValue.uppercased() }.joined(separator: " · ")
                        Text("\(source.bankName) · \(source.sourceType.rawValue) · \(formats)")
                            .font(AppTypography.labelSmall)
                            .foregroundColor(DesignTokens.Text.tertiary)
                    }
                }

                Spacer()

                Button(action: viewModel.resetToSource) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Change source")
                    }
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.accent)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            .padding(AppSpacing.lg)
            .background(DesignTokens.Background.surfaceGlass)

            Divider()

            // Drop zone
            ZStack {
                VStack(spacing: 16) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 32))
                        .foregroundColor(AppColors.accent)

                    VStack(spacing: 4) {
                        Text(viewModel.isDraggedOver ? "Release to upload" : "Drag your file here")
                            .font(AppTypography.headingSmall)
                            .foregroundColor(DesignTokens.Text.primary)

                        Text("or")
                            .font(AppTypography.labelSmall)
                            .foregroundColor(DesignTokens.Text.tertiary)

                        Button(action: { openFilePicker() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Choose file")
                            }
                            .font(AppTypography.labelMedium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppColors.accent)
                            .cornerRadius(AppRadius.md)
                        }
                        .buttonStyle(.plain)

                        let formatHint = viewModel.selectedSource
                            .map { $0.allowedFormats.map { $0.rawValue.uppercased() }.joined(separator: " · ") }
                            ?? "CSV · XLSX · PDF"
                        Text("\(formatHint) · up to 25 MB")
                            .font(AppTypography.labelSmall)
                            .foregroundColor(DesignTokens.Text.quaternary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Drag target overlay
                Rectangle()
                    .fill(Color.clear)
                    .onDrop(of: [.fileURL], isTargeted: $viewModel.isDraggedOver) { providers in
                        var fileURLs: [URL] = []
                        let group = DispatchGroup()

                        for provider in providers {
                            group.enter()
                            provider.loadObject(ofClass: NSURL.self) { nsurl, _ in
                                if let url = nsurl as? URL {
                                    fileURLs.append(url)
                                }
                                group.leave()
                            }
                        }

                        group.notify(queue: .main) {
                            if !fileURLs.isEmpty {
                                Task { @MainActor in
                                    viewModel.parseFiles(fileURLs)
                                }
                            }
                        }
                        return true
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(viewModel.isDraggedOver ? AppColors.accent.opacity(0.05) : AppColors.base)

            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.small)

                    if viewModel.totalFilesToParse > 1 {
                        Text("Parsing file \(viewModel.currentFileIndex + 1) of \(viewModel.totalFilesToParse)...")
                            .font(AppTypography.labelSmall)
                            .foregroundColor(DesignTokens.Text.tertiary)
                    } else {
                        Text("Parsing statement...")
                            .font(AppTypography.labelSmall)
                            .foregroundColor(DesignTokens.Text.tertiary)
                    }
                }
                .padding(AppSpacing.lg)
                .frame(maxWidth: .infinity)
            }

            if let error = viewModel.errorMessage {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppColors.danger)

                    Text(error)
                        .font(AppTypography.labelSmall)
                        .foregroundColor(DesignTokens.Text.primary)

                    Spacer()
                }
                .padding(AppSpacing.md)
                .background(AppColors.danger.opacity(0.1))
                .cornerRadius(AppRadius.sm)
                .padding(AppSpacing.lg)
            }
        }
    }

    // MARK: - Step 3: Review & Confirm

    var reviewStep: some View {
        VStack(spacing: 0) {
            ImportPreviewView(
                viewModel: viewModel
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Private helpers

    private func openFilePicker() {
        let panel = NSOpenPanel()
        let allowedFormats = viewModel.selectedSource?.allowedFormats ?? []
        panel.allowedContentTypes = allowedFormats.map(\.utType)
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true

        if panel.runModal() == .OK, !panel.urls.isEmpty {
            viewModel.parseFiles(panel.urls)
        }
    }
}
