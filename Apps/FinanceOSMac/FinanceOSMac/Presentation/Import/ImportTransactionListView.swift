import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

struct ImportTransactionListView: View {
    let transactions: [ParsedTransaction]
    let duplicateIndices: Set<Int>
    let scrollable: Bool
    let rowLimit: Int?

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

    // MARK: - Row Model

    private struct RowItem: Identifiable {
        let id: Int
        let transaction: ParsedTransaction
        let isDuplicate: Bool
    }

    private var rows: [RowItem] {
        transactions.prefix(rowLimit ?? transactions.count).enumerated().map { index, txn in
            RowItem(id: index, transaction: txn, isDuplicate: duplicateIndices.contains(index))
        }
    }

    /// Estimated height for fixed-frame collapsed mode (36pt rows + 28pt header)
    private var tableHeight: CGFloat? {
        guard let limit = rowLimit else { return nil }
        return CGFloat(min(limit, transactions.count)) * 36 + 28
    }

    // MARK: - Body

    @SceneStorage("import.table.columnCustomization")
    private var columnCustomization: TableColumnCustomization<RowItem>

    var body: some View {
        VStack(spacing: 0) {
            Table(of: RowItem.self, columnCustomization: $columnCustomization) {
                TableColumn("Status") { row in
                    statusBadge(isDuplicate: row.isDuplicate)
                }
                .width(min: 70, ideal: 90, max: 120)
                .customizationID("status")

                TableColumn("Date") { row in
                    FDSLabel(ImportFormatting.formatDate(row.transaction.postedAt))
                        .font(AppTypography.labelMedium)
                        .foregroundColor(AppColors.Text.tertiary)
                }
                .width(min: 80, ideal: 100, max: 140)
                .customizationID("date")

                TableColumn("Description") { row in
                    FDSLabel(row.transaction.description)
                        .font(AppTypography.bodySm)
                        .foregroundColor(AppColors.Text.primary)
                        .lineLimit(1)
                }
                .customizationID("description")

                TableColumn("Reference") { row in
                    FDSLabel(shortReference(row.transaction.sourceFingerprint))
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.Text.quaternary)
                        .lineLimit(1)
                }
                .width(min: 120, ideal: 160, max: 240)
                .customizationID("reference")

                TableColumn("Amount") { row in
                    amountLabel(minorUnits: row.transaction.amountMinorUnits)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .width(min: 90, ideal: 120, max: 160)
                .customizationID("amount")
            } rows: {
                ForEach(rows) { row in
                    TableRow(row)
                }
            }
            .frame(maxHeight: tableHeight ?? .infinity)

            ellipsisIndicator
        }
    }

    // MARK: - Subviews

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

    @ViewBuilder
    private func statusBadge(isDuplicate: Bool) -> some View {
        if isDuplicate {
            FBadge("Duplicate", color: .gray)
        } else {
            FBadge("New", color: .green)
        }
    }

    private func amountLabel(minorUnits: Int64) -> some View {
        let isDebit = minorUnits < 0
        return HStack(spacing: 2) {
            FDSLabel(isDebit ? "−" : "+")
            FDSLabel(ImportFormatting.formatAmount(abs(minorUnits)))
        }
        .font(AppTypography.amountSm)
        .foregroundColor(isDebit ? AppColors.debit : AppColors.credit)
    }

    private func shortReference(_ fingerprint: String) -> String {
        let prefix = fingerprint.prefix(16)
        return prefix.isEmpty ? "–" : String(prefix)
    }
}
