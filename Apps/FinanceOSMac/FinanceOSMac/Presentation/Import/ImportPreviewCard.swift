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
                .font(.headline)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(parsedStatements.count)")
                        .font(.body)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Transactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(totalTransactions)")
                        .font(.body)
                        .fontWeight(.semibold)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Debits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(ImportFormatting.formatAmount(totalDebit))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Credits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(ImportFormatting.formatAmount(totalCredit))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
    }
}
