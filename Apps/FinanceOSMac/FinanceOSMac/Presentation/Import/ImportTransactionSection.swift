import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

struct ImportTransactionSection: View {
    let title: String
    let badgeCount: Int
    let transactions: [ParsedTransaction]
    let duplicateIndices: Set<Int>
    @Binding var isExpanded: Bool

    private let collapsedRowLimit: Int = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader
            Divider()
            sectionContent
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .strokeBorder(DesignTokens.Border.subtle, lineWidth: 1)
        )
    }

    // MARK: - Header

    private var sectionHeader: some View {
        HStack(spacing: AppSpacing.md) {
            HStack(spacing: 8) {
                Text(title)
                    .font(AppTypography.headingSmall)
                    .foregroundColor(DesignTokens.Text.primary)

                FBadge(String(badgeCount), color: .blue)
            }

            Spacer()

            viewAllButton
        }
        .padding(AppSpacing.md)
        .background(DesignTokens.Background.surfaceGlass)
    }

    // MARK: - View All Button

    private var viewAllButton: some View {
        Button(action: { isExpanded.toggle() }) {
            Text(isExpanded ? "Show Less" : "View All")
                .font(AppTypography.labelMedium)
                .foregroundColor(AppColors.accent)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    // MARK: - Content

    @ViewBuilder
    private var sectionContent: some View {
        if isExpanded {
            ImportTransactionListView(
                transactions: transactions,
                duplicateIndices: duplicateIndices,
                scrollable: true,
                rowLimit: nil
            )
        } else {
            ImportTransactionListView(
                transactions: transactions,
                duplicateIndices: duplicateIndices,
                scrollable: true,
                rowLimit: collapsedRowLimit
            )
        }
    }
}

#Preview {
    @Previewable @State var expanded = true

    let txns = [
        ParsedTransaction(
            postedAt: Date(),
            description: "Starbucks Coffee",
            amountMinorUnits: -450,
            currencyCode: "INR",
            sourceFingerprint: "abc123"
        ),
        ParsedTransaction(
            postedAt: Date(),
            description: "Amazon Purchase",
            amountMinorUnits: -5000,
            currencyCode: "INR",
            sourceFingerprint: "def456"
        ),
        ParsedTransaction(
            postedAt: Date(),
            description: "Salary Credit",
            amountMinorUnits: 100_000,
            currencyCode: "INR",
            sourceFingerprint: "ghi789"
        )
    ]

    ImportTransactionSection(
        title: "Imported Transactions",
        badgeCount: 12,
        transactions: txns,
        duplicateIndices: [],
        isExpanded: $expanded
    )
    .padding()
}
