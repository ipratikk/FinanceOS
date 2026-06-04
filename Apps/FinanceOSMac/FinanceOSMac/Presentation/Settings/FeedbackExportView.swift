import FinanceCore
import FinanceUI
import SwiftUI

struct FeedbackExportView: View {
    var viewModel: FeedbackExportViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionTitle("Training Feedback")
            FDSCard(cornerRadius: 12, padded: false) {
                VStack(spacing: 0) {
                    correctionCountRow
                    Divider().opacity(AppColors.Opacity.low).padding(.vertical, 8)
                    lastExportRow
                    if viewModel.canExport || viewModel.exportedFileURL != nil {
                        Divider().opacity(AppColors.Opacity.low).padding(.vertical, 8)
                        exportActionRow
                    }
                    if let error = viewModel.exportError {
                        Divider().opacity(AppColors.Opacity.low).padding(.vertical, 8)
                        FDSBanner(error, style: .error)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.bottom, AppSpacing.sm)
                    }
                }
                .padding(AppSpacing.sm)
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        FDSLabel(title)
            .font(AppTypography.bodyMdSemibold)
            .foregroundStyle(AppColors.Text.primary)
    }

    private var correctionCountRow: some View {
        HStack(spacing: AppSpacing.compact) {
            Image(systemName: "hand.thumbsup.fill")
                .font(AppTypography.bodySmMedium)
                .foregroundStyle(AppColors.accentPurple)
                .frame(width: 22)
            FDSLabel("Corrections Recorded")
                .font(AppTypography.bodySmMedium)
                .foregroundStyle(AppColors.Text.primary)
            Spacer()
            countBadge
        }
    }

    private var countBadge: some View {
        let threshold = 50
        let met = viewModel.correctionCount >= threshold
        let color: Color = met ? AppColors.success : AppColors.Text.tertiary
        return FDSLabel("\(viewModel.correctionCount)")
            .font(AppTypography.captionSmSemibold)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    private var lastExportRow: some View {
        HStack(spacing: AppSpacing.compact) {
            Image(systemName: "clock")
                .font(AppTypography.bodySmMedium)
                .foregroundStyle(AppColors.Text.secondary)
                .frame(width: 22)
            FDSLabel("Last Export")
                .font(AppTypography.bodySmMedium)
                .foregroundStyle(AppColors.Text.primary)
            Spacer()
            FDSLabel(viewModel.exportStatusText)
                .font(AppTypography.captionSmSemibold)
                .foregroundStyle(AppColors.Text.tertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppColors.Text.tertiary.opacity(0.12))
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private var exportActionRow: some View {
        if let url = viewModel.exportedFileURL {
            ShareLink(item: url, preview: SharePreview("feedback_export.csv")) {
                exportButtonLabel(label: "Share Exported CSV", symbol: "square.and.arrow.up", tint: AppColors.accent)
            }
            .buttonStyle(.plain)
        } else if viewModel.canExport {
            Button(action: {
                Task { await viewModel.exportFeedback() }
            }, label: {
                if viewModel.isExporting {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        FDSLabel("Exporting…")
                            .font(AppTypography.bodySmSemibold)
                        Spacer()
                    }
                } else {
                    exportButtonLabel(
                        label: "Export Feedback CSV",
                        symbol: "arrow.down.doc.fill",
                        tint: AppColors.accent
                    )
                }
            })
            .disabled(viewModel.isExporting)
            .buttonStyle(.plain)
        }
    }

    private func exportButtonLabel(label: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(AppTypography.bodySmSemibold)
            FDSLabel(label)
                .font(AppTypography.bodySmSemibold)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(tint.opacity(0.18))
        .foregroundStyle(tint)
        .cornerRadius(8)
    }
}
