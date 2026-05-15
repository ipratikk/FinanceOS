import FinanceCore
import FinanceParsers
import SwiftUI

struct ImportFileListView: View {
    let fileStatementPairs: [(url: URL, statement: ParsedStatement)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Files")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(fileStatementPairs.indices, id: \.self) { index in
                    let pair = fileStatementPairs[index]

                    HStack(spacing: 12) {
                        Image(systemName: "doc.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 16)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(pair.url.lastPathComponent)
                                .font(.body)
                                .lineLimit(1)

                            Text(pair.statement.bankName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("\(pair.statement.transactions.count) txns")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface2)
                    .cornerRadius(AppRadius.md)
                }
            }
        }
        .padding()
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
    }
}
