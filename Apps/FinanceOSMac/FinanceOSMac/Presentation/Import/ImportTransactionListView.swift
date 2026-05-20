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
                FDSLabel("… and \(transactions.count - limit) more")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(AppColors.Text.quaternary)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
    }

    private var tableHeader: some View {
        HStack(spacing: AppSpacing.md) {
            FDSLabel("Status")
                .font(AppTypography.labelMedium)
                .foregroundColor(AppColors.Text.secondary)
                .frame(width: 80, alignment: .leading)

            FDSLabel("Date")
                .font(AppTypography.labelMedium)
                .foregroundColor(AppColors.Text.secondary)
                .frame(width: 80, alignment: .leading)

            FDSLabel("Description")
                .font(AppTypography.labelMedium)
                .foregroundColor(AppColors.Text.secondary)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            FDSLabel("Reference")
                .font(AppTypography.labelMedium)
                .foregroundColor(AppColors.Text.secondary)
                .frame(width: 120, alignment: .leading)

            FDSLabel("Amount")
                .font(AppTypography.labelMedium)
                .foregroundColor(AppColors.Text.secondary)
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

            FDSLabel(ImportFormatting.formatDate(txn.postedAt))
                .font(AppTypography.labelMedium)
                .foregroundColor(AppColors.Text.tertiary)
                .frame(width: 80, alignment: .leading)

            FDSLabel(txn.description)
                .font(AppTypography.bodySm)
                .foregroundColor(AppColors.Text.primary)
                .lineLimit(1)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            FDSLabel(shortReference(txn.sourceFingerprint))
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.Text.quaternary)
                .lineLimit(1)
                .frame(width: 120, alignment: .leading)

            amountLabel(minorUnits: txn.amountMinorUnits, isDebit: isDebit)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(isDuplicate ? AppColors.Glass.surface.opacity(0.5) : AppColors.clear)
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
            FDSLabel(isDebit ? "−" : "+")
            FDSLabel(ImportFormatting.formatAmount(abs(minorUnits)))
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
