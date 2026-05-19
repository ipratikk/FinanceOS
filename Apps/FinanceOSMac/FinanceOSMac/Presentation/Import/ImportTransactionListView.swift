import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

struct ImportTransactionListView: View {
    // MARK: - Properties

    let transactions: [ParsedTransaction]
    let duplicateIndices: Set<Int>
    let scrollable: Bool
    let rowLimit: Int?

    // MARK: - Init

    init(
        transactions: [ParsedTransaction],
        duplicateIndices: Set<Int> = [],
        scrollable: Bool = true,
        rowLimit: Int? = nil
    ) {
        self.transactions = transactions
        self.duplicateIndices = duplicateIndices
        self.scrollable = scrollable
        self.rowLimit = rowLimit
    }

    // MARK: - Body

    var body: some View {
        VStack {
            tableHeader
            tableView
        }
    }

    // MARK: - Table View

    @ViewBuilder
    private var tableView: some View {
        if scrollable {
            ScrollView {
                tableViewContent
            }
        } else {
            tableViewContent
        }
    }

    private var tableViewContent: some View {
        VStack(spacing: 0) {
            tableRows
            ellipsisIndicator
        }
        .background(AppColors.base)
        .cornerRadius(AppRadius.md)
    }

    @ViewBuilder
    private var ellipsisIndicator: some View {
        if let limit = rowLimit, transactions.count > limit {
            HStack {
                Text("… and \(transactions.count - limit) more")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(DesignTokens.Text.quaternary)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
    }

    private var tableHeader: some View {
        HStack(spacing: AppSpacing.md) {
            Text("Status")
                .font(AppTypography.labelMedium)
                .foregroundColor(DesignTokens.Text.secondary)
                .frame(width: 80, alignment: .leading)

            Text("Date")
                .font(AppTypography.labelMedium)
                .foregroundColor(DesignTokens.Text.secondary)
                .frame(width: 80, alignment: .leading)

            Text("Description")
                .font(AppTypography.labelMedium)
                .foregroundColor(DesignTokens.Text.secondary)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            Text("Reference")
                .font(AppTypography.labelMedium)
                .foregroundColor(DesignTokens.Text.secondary)
                .frame(width: 120, alignment: .leading)

            Text("Amount")
                .font(AppTypography.labelMedium)
                .foregroundColor(DesignTokens.Text.secondary)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.surface)
    }

    private var tableRows: some View {
        let visibleTransactions = Array(transactions.prefix(rowLimit ?? transactions.count))
        return VStack(spacing: 0) {
            ForEach(visibleTransactions.indices, id: \.self) { index in
                tableRow(at: index)

                if index < visibleTransactions.count - 1 {
                    Divider()
                }
            }
        }
    }

    private func tableRow(at index: Int) -> some View {
        let txn = transactions[index]
        let isDuplicate = duplicateIndices.contains(index)
        let isDebit = txn.amountMinorUnits < 0

        return HStack(spacing: AppSpacing.md) {
            statusBadge(isDuplicate: isDuplicate)
                .frame(width: 80, alignment: .leading)

            Text(ImportFormatting.formatDate(txn.postedAt))
                .font(AppTypography.labelMedium)
                .foregroundColor(DesignTokens.Text.tertiary)
                .frame(width: 80, alignment: .leading)

            Text(txn.description)
                .font(AppTypography.bodySm)
                .foregroundColor(DesignTokens.Text.primary)
                .lineLimit(1)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            Text(shortReference(txn.sourceFingerprint))
                .font(AppTypography.labelSmall)
                .foregroundColor(DesignTokens.Text.quaternary)
                .lineLimit(1)
                .frame(width: 120, alignment: .leading)

            amountLabel(minorUnits: txn.amountMinorUnits, isDebit: isDebit)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(isDuplicate ? DesignTokens.Background.surfaceGlass.opacity(0.5) : Color.clear)
    }

    @ViewBuilder
    private func statusBadge(isDuplicate: Bool) -> some View {
        if isDuplicate {
            FBadge("Duplicate", color: .gray)
        } else {
            FBadge("New", color: .green)
        }
    }

    private func amountLabel(minorUnits: Int64, isDebit: Bool) -> some View {
        HStack(spacing: 2) {
            Text(isDebit ? "−" : "+")
            Text(ImportFormatting.formatAmount(abs(minorUnits)))
        }
        .font(AppTypography.amountSm)
        .foregroundColor(isDebit ? AppColors.debit : AppColors.credit)
    }

    // MARK: - List Content

    // MARK: - Helpers

    private func shortReference(_ fingerprint: String) -> String {
        let prefix = fingerprint.prefix(16)
        return prefix.isEmpty ? "–" : String(prefix)
    }
}
