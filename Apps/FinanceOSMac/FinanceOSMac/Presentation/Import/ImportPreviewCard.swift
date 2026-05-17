import FinanceCore
import FinanceParsers
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
            Text("Import Summary")
                .headingSmall()

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Files")
                        .caption()
                    Text("\(parsedStatements.count)")
                        .bodyLarge()
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Transactions")
                        .caption()
                    Text("\(totalTransactions)")
                        .bodyLarge()
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Debits")
                        .caption()
                    Text(ImportFormatting.formatAmount(totalDebit))
                        .bodyLarge()
                        .foregroundColor(AppColors.debit)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Credits")
                        .caption()
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
