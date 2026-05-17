import FinanceCore
import FinanceParsers
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
                    Text("New Transactions")
                        .caption()
                    Text("\(newTransactionCount)")
                        .bodyLarge()
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Already Imported")
                        .caption()
                    Text("\(duplicateIndices.count)")
                        .bodyLarge()
                        .foregroundColor(AppColors.warning)
                }
            }

            Divider()

            Text("Transactions (\(transactions.count))")
                .headingSmall()

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
                        Text(txn.description)
                            .bodyLarge()
                            .lineLimit(1)
                            .opacity(isDuplicate ? 0.5 : 1.0)

                        HStack(spacing: 8) {
                            Text(ImportFormatting.formatDate(txn.postedAt))
                                .caption()

                            if isDuplicate {
                                Text("Already imported")
                                    .caption()
                                    .foregroundColor(AppColors.warning)
                            }

                            if let points = txn.rewardPoints, points > 0 {
                                Text("+\(points) pts")
                                    .caption()
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                    }

                    Spacer()

                    Text(ImportFormatting.formatAmount(txn.amountMinorUnits))
                        .bodyLarge()
                        .foregroundColor(txn.amountMinorUnits < 0 ? AppColors.debit : AppColors.credit)
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
