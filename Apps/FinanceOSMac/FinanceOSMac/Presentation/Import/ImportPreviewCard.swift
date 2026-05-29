import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

struct ImportPreviewCard: View {
    let parsedStatements: [ParsedStatement]

    private var totalTransactions: Int {
        parsedStatements.reduce(0) { $0 + $1.transactions.count }
    }

    private var totalDebit: Int64 {
        parsedStatements.reduce(0) { $0 + $1.totalDebit }
    }

    private var totalCredit: Int64 {
        parsedStatements.reduce(0) { $0 + $1.totalCredit }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FDSLabel("Import Summary")
                .font(AppTypography.headingSmall)
                .foregroundStyle(AppColors.Text.primary)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    FDSLabel("Total Files")
                        .font(AppTypography.captionSm)
                        .foregroundStyle(AppColors.Text.primary)
                    FDSLabel("\(parsedStatements.count)")
                        .font(AppTypography.bodyLg)
                        .foregroundStyle(AppColors.Text.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    FDSLabel("Total Transactions")
                        .font(AppTypography.captionSm)
                        .foregroundStyle(AppColors.Text.primary)
                    FDSLabel("\(totalTransactions)")
                        .font(AppTypography.bodyLg)
                        .foregroundStyle(AppColors.Text.primary)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    FDSLabel("Total Debits")
                        .font(AppTypography.captionSm)
                        .foregroundStyle(AppColors.Text.primary)
                    FDSLabel(FormatterCache.formatCurrency(minorUnits: totalDebit))
                        .font(AppTypography.bodyLg)
                        .foregroundStyle(AppColors.Text.primary)
                        .foregroundColor(AppColors.debit)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    FDSLabel("Total Credits")
                        .font(AppTypography.captionSm)
                        .foregroundStyle(AppColors.Text.primary)
                    FDSLabel(FormatterCache.formatCurrency(minorUnits: totalCredit))
                        .font(AppTypography.bodyLg)
                        .foregroundStyle(AppColors.Text.primary)
                        .foregroundColor(AppColors.credit)
                }
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
    }
}
