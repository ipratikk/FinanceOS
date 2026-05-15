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
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(newTransactionCount)")
                        .font(.body)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Already Imported")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(duplicateIndices.count)")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }

            Divider()

            Text("Transactions (\(transactions.count))")
                .font(.headline)

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
                        .fill(txn.amountMinorUnits < 0 ? Color.red : Color.green)
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(txn.description)
                            .font(.body)
                            .lineLimit(1)
                            .opacity(isDuplicate ? 0.5 : 1.0)

                        HStack(spacing: 8) {
                            Text(ImportFormatting.formatDate(txn.postedAt))
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if isDuplicate {
                                Text("Already imported")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }

                            if let points = txn.rewardPoints, points > 0 {
                                Text("+\(points) pts")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    Spacer()

                    Text(ImportFormatting.formatAmount(txn.amountMinorUnits))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(txn.amountMinorUnits < 0 ? .red : .green)
                        .opacity(isDuplicate ? 0.5 : 1.0)
                }
                .padding(AppSpacing.sm)
                .background(AppColors.surface2)
                .cornerRadius(AppRadius.md)
            }

            if transactions.count > 5 {
                Text("... and \(transactions.count - 5) more transactions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
        }
    }
}
