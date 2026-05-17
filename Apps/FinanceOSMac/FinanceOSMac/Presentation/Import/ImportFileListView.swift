import FinanceCore
import FinanceParsers
import SwiftUI

struct ImportFileListView: View {
    let fileStatementPairs: [(url: URL, statement: ParsedStatement)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Files")
                .headingSmall()

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
                                .bodyLarge()
                                .lineLimit(1)

                            Text(pair.statement.bankName)
                                .caption()
                        }

                        Spacer()

                        Text("\(pair.statement.transactions.count) txns")
                            .caption()
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
