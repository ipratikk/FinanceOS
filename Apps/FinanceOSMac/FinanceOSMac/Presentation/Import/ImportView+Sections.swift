import FinanceCore
import FinanceParsers
import SwiftUI

struct SupportedSourcesView: View {
    let viewModel: ImportViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Supported Statements")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(viewModel.supportedSources.enumerated()), id: \.offset) { _, source in
                    let isFullySupported = source.bankName == "ICICI" && source.sourceType == .bankAccount
                    let status = isFullySupported ? "" : " (coming soon)"
                    Text("• \(source.bankName) \(source.sourceType.rawValue)\(status)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Divider()
            Text("💡 CSV and XLSX for CSV-based statements; TXT for delimited text (HDFC); PDF for scanned statements.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(4)
    }
}

struct TargetSelectionSection: View {
    let viewModel: ImportViewModel
    @Binding var targetChoice: TargetChoice?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Import To")
                .font(.headline)

            Picker("Target", selection: $targetChoice) {
                Text("Select Account or Card...").tag(nil as TargetChoice?)

                if !viewModel.accounts.isEmpty {
                    Divider()
                    Text("Accounts").font(.caption).tag(nil as TargetChoice?)

                    ForEach(viewModel.accounts) { account in
                        Text(account.accountName)
                            .tag(TargetChoice.account(account.id) as TargetChoice?)
                    }
                }

                if !viewModel.cards.isEmpty {
                    Divider()
                    Text("Cards").font(.caption).tag(nil as TargetChoice?)

                    ForEach(viewModel.cards) { card in
                        Text(card.cardName)
                            .tag(TargetChoice.card(card.id) as TargetChoice?)
                    }
                }
            }
        }
    }
}
