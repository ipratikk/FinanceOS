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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Import To")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray)

                    Text("Select or create target")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(red: 0.447, green: 0.447, blue: 0.478))
                }

                Spacer()

                if targetChoice != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.231, green: 0.510, blue: 0.980))
                }
            }

            Picker("Target", selection: $targetChoice) {
                Text("Select target...").tag(nil as TargetChoice?)

                if !viewModel.accounts.isEmpty {
                    Section("Accounts") {
                        ForEach(viewModel.accounts) { account in
                            Text(account.accountName)
                                .tag(TargetChoice.account(account.id) as TargetChoice?)
                        }
                    }
                }

                if !viewModel.cards.isEmpty {
                    Section("Cards") {
                        ForEach(viewModel.cards) { card in
                            Text(card.cardName)
                                .tag(TargetChoice.card(card.id) as TargetChoice?)
                        }
                    }
                }

                Section("Create New") {
                    Text("New Account")
                        .tag(TargetChoice.createAccount as TargetChoice?)
                    Text("New Card")
                        .tag(TargetChoice.createCard as TargetChoice?)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color(red: 0.110, green: 0.110, blue: 0.122))
            .cornerRadius(6)
        }
        .padding(12)
        .background(Color(red: 0.086, green: 0.086, blue: 0.098))
        .cornerRadius(10)
    }
}
