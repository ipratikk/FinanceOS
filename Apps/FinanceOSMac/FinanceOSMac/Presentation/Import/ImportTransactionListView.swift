import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

struct ImportTransactionListView: View {
    let transactions: [ParsedTransaction]
    let duplicateIndices: Set<Int>

    private var newTransactionCount: Int {
        transactions.count - duplicateIndices.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    FDSLabel("New Transactions", style: .caption)
                    FDSLabel("\(newTransactionCount)", style: .bodyLarge)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    FDSLabel("Already Imported", style: .caption)
                    FDSLabel("\(duplicateIndices.count)", style: .bodyLarge, color: .warning)
                }
            }

            Divider()

            FDSLabel("Transactions (\(transactions.count))", style: .heading)

            transactionListContent()
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
    }

    private func transactionListContent() -> some View {
        let firstFive = Array(transactions.prefix(5))

        return VStack(spacing: 8) {
            ForEach(firstFive.indices, id: \.self) { index in
                let txn = firstFive[index]
                let isDuplicate = duplicateIndices.contains(index)

                HStack(spacing: 12) {
                    Circle()
                        .fill(txn.amountMinorUnits < 0 ? AppColors.debit : AppColors.credit)
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 2) {
                        FDSLabel(txn.description, style: .bodyLarge)
                            .lineLimit(1)
                            .opacity(isDuplicate ? 0.5 : 1.0)

                        HStack(spacing: 8) {
                            FDSLabel(ImportFormatting.formatDate(txn.postedAt), style: .caption)

                            if isDuplicate {
                                FDSLabel("Already imported", style: .caption)
                            }

                            if let points = txn.rewardPoints, points > 0 {
                                FDSLabel("+\(points) pts", style: .caption)
                            }
                        }
                    }

                    Spacer()

                    FDSAmount(
                        ImportFormatting.formatAmount(txn.amountMinorUnits),
                        type: txn.amountMinorUnits < 0 ? .debit : .credit
                    )
                    .opacity(isDuplicate ? 0.5 : 1.0)
                }
                .padding(AppSpacing.sm)
                .background(AppColors.surface2)
                .cornerRadius(AppRadius.md)
            }

            if transactions.count > 5 {
                HStack {
                    Text("... and \(transactions.count - 5) more transactions")
                        .caption()
                    Spacer()
                    if duplicateIndices.count > 0 {
                        Text("\(duplicateIndices.count) already imported")
                            .caption()
                            .foregroundColor(AppColors.warning)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}
