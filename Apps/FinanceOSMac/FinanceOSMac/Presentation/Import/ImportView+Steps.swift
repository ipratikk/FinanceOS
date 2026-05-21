import AppKit
import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI
import UniformTypeIdentifiers

extension ImportView {
    // MARK: - Step 1: Source Selection

    var sourceStep: some View {
        VStack(alignment: .leading) {
            // Header
            VStack(alignment: .leading, spacing: AppSpacing.compact) {
                FDSLabel("Where is your statement from?")
                    .font(AppTypography.headingXL)
                    .foregroundColor(AppColors.accent)

                FDSLabel(
                    "Select an institution and ledger type to begin the secure import process."
                )
                .font(AppTypography.captionSm)
                .foregroundColor(AppColors.Text.tertiaryElevated)
            }
            .padding(.bottom, AppSpacing.md)

            Divider()

            // Source grid
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    ImportSourceGrid(
                        sources: StatementSource.allCases,
                        selectedSource: viewModel.selectedSource,
                        onSelectSource: viewModel.selectSourceAndAdvance(_:)
                    )

                    Spacer()
                }
            }
            .padding(.top, AppSpacing.xxxl)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Step 2: File Upload

    var uploadStep: some View {
        VStack {
            // Header with back button
            FDSCard(content: {
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.tight) {
                        FDSLabel("Source Selected")
                            .font(AppTypography.headingMd)
                            .foregroundColor(AppColors.accent)

                        if let source = viewModel.selectedSource {
                            let formats = source.allowedFormats.map { $0.rawValue.uppercased() }
                                .joined(separator: " · ")
                            FDSLabel("\(source.bankName) · \(source.sourceType.rawValue) · \(formats)")
                                .font(AppTypography.labelSmall)
                                .foregroundColor(AppColors.Text.tertiary)
                        }
                    }

                    Spacer()

                    FDSLiquidButton(
                        "Change source",
                        symbol: "chevron.left",
                        variant: .link,
                        action: viewModel.resetToSource
                    )
                }
                .padding(AppSpacing.lg)
            })

            // Drop zone
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

                        FDSLiquidButton("Choose file", symbol: "doc", variant: .primary, action: openFilePicker)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Drag target overlay
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

            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.small)

                    if viewModel.totalFilesToParse > 1 {
                        FDSLabel("Parsing file \(viewModel.currentFileIndex + 1) of \(viewModel.totalFilesToParse)...")
                            .font(AppTypography.labelSmall)
                            .foregroundColor(AppColors.Text.tertiary)
                    } else {
                        FDSLabel("Parsing statement...")
                            .font(AppTypography.labelSmall)
                            .foregroundColor(AppColors.Text.tertiary)
                    }
                }
                .padding(AppSpacing.lg)
                .frame(maxWidth: .infinity)
            }

            if let error = viewModel.errorMessage {
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

            Divider()
            uploadTrustBanners
        }
    }

    private var uploadTrustBanners: some View {
        HStack(spacing: AppSpacing.md) {
            uploadTrustBanner(
                icon: "lock.shield.fill",
                title: "Local Processing",
                body: "Files are parsed on-device. Your financial data never leaves your computer."
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
