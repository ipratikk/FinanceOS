import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

struct ImportFileListView: View {
    let fileStatementPairs: [(url: URL, statement: ParsedStatement)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FDSLabel("Files", style: .heading)

            VStack(spacing: 8) {
                ForEach(fileStatementPairs.indices, id: \.self) { index in
                    let pair = fileStatementPairs[index]

                    HStack(spacing: 12) {
                        Image(systemName: "doc.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 16)

                        VStack(alignment: .leading, spacing: 2) {
                            FDSText(pair.url.lastPathComponent, style: .bodyLarge)
                                .lineLimit(1)

                            FDSLabel(pair.statement.bankName, style: .caption)
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
