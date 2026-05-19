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
            FDSLabel("Import Summary", style: .heading)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    FDSLabel("Total Files", style: .caption)
                    Text("\(parsedStatements.count)")
                        .bodyLarge()
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    FDSLabel("Total Transactions", style: .caption)
                    Text("\(totalTransactions)")
                        .bodyLarge()
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    FDSLabel("Total Debits", style: .caption)
                    Text(ImportFormatting.formatAmount(totalDebit))
                        .bodyLarge()
                        .foregroundColor(AppColors.debit)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    FDSLabel("Total Credits", style: .caption)
                    Text(ImportFormatting.formatAmount(totalCredit))
                        .bodyLarge()
                        .foregroundColor(AppColors.credit)
                }
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
    }
}
