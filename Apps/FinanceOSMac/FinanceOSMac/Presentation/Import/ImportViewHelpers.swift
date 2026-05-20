import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI
import UniformTypeIdentifiers

struct SourcePickerSection: View {
    @Binding var selectedSource: StatementSource?
    let errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    FDSLabel("1. Statement Source", style: .subheading)

                    FDSLabel("Select your bank", style: .hint)
                }

                Spacer()

                if selectedSource != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .headingSmall()
                        .foregroundColor(AppColors.accent)
                }
            }

            if let error = errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(AppTypography.captionLg)
                            .foregroundColor(AppColors.debit)

                        FDSLabel(error, style: .hint)
                            .lineLimit(3)
                    }
                }
                .padding(AppSpacing.xs)
                .background(AppColors.debit.opacity(0.1))
                .cornerRadius(AppRadius.sm)
            }

            ImportSourceGrid(
                sources: StatementSource.allCases,
                selectedSource: selectedSource,
                onSelectSource: { source in
                    selectedSource = selectedSource == source ? nil : source
                }
            )
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
    }
}

struct DropZoneView: View {
    let selectedSource: StatementSource?
    @State private var isHovered = false

    var body: some View {
        let formatNames = selectedSource?.allowedFormats.map { $0.rawValue.uppercased() }
            .joined(separator: ", ") ?? ""

        return VStack(spacing: 12) {
            VStack(spacing: 12) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(AppTypography.headingMd)
                    .foregroundColor(AppColors.accent)

                VStack(spacing: 4) {
                    FDSLabel("Drop files here", style: .monoAmount)

                    FDSLabel("or click button below", style: .hint)

                    FDSLabel("Supported: \(formatNames)")
                        .labelSmall()
                        .foregroundColor(AppColors.textTertiary)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                AppColors.surface2
                    .opacity(isHovered ? 1 : 0.5)
            )
            .cornerRadius(AppRadius.md)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
    }
}

struct FileSelectionPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.doc.fill")
                .font(AppTypography.headingMd)
                .foregroundColor(AppColors.textTertiary)

            VStack(spacing: 4) {
                FDSLabel("Select a bank above", style: .monoAmount, color: .tertiary)

                FDSLabel("to start importing", style: .hint)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
    }
}
