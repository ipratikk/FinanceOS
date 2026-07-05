import AppKit
import FinanceCore
import FinanceUI
import SwiftUI
import UniformTypeIdentifiers

extension ImportView {
    // MARK: - Idle: drop zone

    var idleContent: some View {
        VStack {
            ZStack {
                VStack(spacing: AppSpacing.xl) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(AppTypography.displaySmall)
                        .foregroundColor(AppColors.accent)

                    VStack(spacing: AppSpacing.md) {
                        FDSLabel(viewModel.isDraggedOver ? "Release to upload" : "Drag and drop statement")
                            .font(AppTypography.headingXL)
                            .foregroundColor(AppColors.Text.primary)

                        if !viewModel.isDraggedOver {
                            FDSLabel("Upload your bank statement in PDF, CSV, or XLSX format. Max file size is 10MB.")
                                .font(AppTypography.bodyLg)
                                .foregroundColor(AppColors.Text.tertiary)
                        }

                        FDSLiquidButton("Choose file", leadingIcon: "doc", variant: .primary, action: openFilePicker)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Rectangle()
                    .fill(AppColors.clear)
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
            .layoutPriority(1)
            .background(viewModel.isDraggedOver ? AppColors.accent.opacity(0.05) : AppColors.base)

            if let error = viewModel.errorMessage {
                errorBanner(error)
            }

            Divider()
            uploadTrustBanners
        }
    }

    // MARK: - Previewing: spinner while previewStatement runs

    var previewingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)

            if viewModel.totalFilesToParse > 1 {
                FDSLabel("Previewing file \(viewModel.currentFileIndex + 1) of \(viewModel.totalFilesToParse)...")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(AppColors.Text.tertiary)
            } else {
                FDSLabel("Previewing statement...")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(AppColors.Text.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Ready to import: detected info + target + Import button

    var readyToImportContent: some View {
        VStack(spacing: 0) {
            if let error = viewModel.errorMessage {
                errorBanner(error)
            }

            FDSCard(padded: false) {
                HStack(spacing: AppSpacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        FDSLabel("Ready to import")
                            .font(AppTypography.headingMd)
                            .foregroundColor(AppColors.accent)

                        FDSLabel(detectedSummary)
                            .font(AppTypography.labelSmall)
                            .foregroundColor(AppColors.Text.tertiary)
                    }
                    Spacer()
                    ImportTargetSection(viewModel: viewModel)
                }
                .padding(AppSpacing.lg)
            }

            ScrollView {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.fileStatementPairs, id: \.url) { pair in
                        detectedFileRow(pair)
                    }
                }
                .padding(AppSpacing.lg)
            }

            Spacer()

            FDSCard(padded: false) {
                HStack(spacing: AppSpacing.md) {
                    FDSLiquidButton("Cancel", variant: .ghost, action: viewModel.resetToIdle)
                    Spacer()
                    FDSLiquidButton(
                        "Import",
                        variant: .primary,
                        isEnabled: viewModel.selectedTarget != nil,
                        action: viewModel.importTransactions
                    )
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
            }
        }
    }

    // MARK: - Importing: spinner

    var importingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
            FDSLabel("Importing...")
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.Text.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Shared helpers

    private var detectedSummary: String {
        let fileCount = viewModel.parsedStatements.count
        return fileCount == 1
            ? (viewModel.fileURLs.first?.lastPathComponent ?? "1 file")
            : "\(fileCount) files"
    }

    private func detectedFileRow(_ pair: (url: URL, statement: ParsedStatement)) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                FDSLabel(pair.url.lastPathComponent)
                    .font(AppTypography.bodyLg)
                    .foregroundStyle(AppColors.Text.primary)
                    .lineLimit(1)

                FDSLabel(pair.statement.bankName)
                    .font(AppTypography.captionSm)
                    .foregroundStyle(AppColors.Text.primary)
            }

            Spacer()

            if let last4 = pair.statement.cardLast4 ?? pair.statement.accountLast4 {
                FDSLabel("•••• \(last4)")
                    .font(AppTypography.captionLg)
                    .foregroundStyle(AppColors.Text.tertiary)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface2)
        .cornerRadius(AppRadius.md)
    }

    private func errorBanner(_ error: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppColors.danger)
            FDSLabel(error)
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.Text.primary)
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.danger.opacity(0.1))
        .cornerRadius(AppRadius.sm)
        .padding(AppSpacing.lg)
    }

    private var uploadTrustBanners: some View {
        HStack(spacing: AppSpacing.md) {
            uploadTrustBanner(
                icon: "lock.shield.fill",
                title: "Secure Upload",
                body: "Statements are sent to your FinanceOS backend for parsing — "
                    + "nothing is stored until you confirm the import."
            )
            uploadTrustBanner(
                icon: "key.fill",
                title: "Password Protected?",
                body: "You'll be prompted if your file requires a password to open."
            )
        }
        .padding(AppSpacing.lg)
    }

    private func uploadTrustBanner(icon: String, title: String, body: String) -> some View {
        FDSCard {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                FDSImage(fallbackSymbol: icon)
                    .font(AppTypography.bodyLg)
                    .foregroundColor(AppColors.accent)

                VStack(alignment: .leading, spacing: AppSpacing.compact) {
                    FDSLabel(title)
                        .font(AppTypography.labelMedium)
                        .foregroundColor(AppColors.Text.primary)
                    FDSLabel(body)
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.Text.secondary)
                }

                Spacer()
            }
        }
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            FinanceCore.StatementFileFormat.csv.utType,
            FinanceCore.StatementFileFormat.txt.utType,
            FinanceCore.StatementFileFormat.xlsx.utType,
            FinanceCore.StatementFileFormat.pdf.utType
        ]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true

        if panel.runModal() == .OK, !panel.urls.isEmpty {
            viewModel.parseFiles(panel.urls)
        }
    }
}
