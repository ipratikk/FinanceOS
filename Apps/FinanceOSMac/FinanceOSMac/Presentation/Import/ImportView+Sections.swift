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
        .cornerRadius(AppRadius.sm)
    }
}

struct TargetSelectionSection: View {
    let viewModel: ImportViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Import To")
                        .captionLarge()
                        .foregroundColor(.gray)

                    Text("Select or create target")
                        .labelSmall()
                        .foregroundColor(AppColors.textTertiary)
                }

                Spacer()

                if viewModel.selectedTarget != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .headingSmall()
                        .foregroundColor(AppColors.accent)
                }
            }

            Menu {
                if viewModel.selectedTarget != nil {
                    Button(action: { viewModel.selectedTarget = nil }) {
                        Text("Clear")
                    }
                    Divider()
                }

                if !viewModel.accounts.isEmpty {
                    Menu("Accounts") {
                        ForEach(viewModel.accounts) { account in
                            Button(action: { viewModel.selectedTarget = .account(account.id) }) {
                                if case .account(let id) = viewModel.selectedTarget, id == account.id {
                                    Label(account.accountName, systemImage: "checkmark")
                                } else {
                                    Text(account.accountName)
                                }
                            }
                        }
                    }
                }

                if !viewModel.cards.isEmpty {
                    Menu("Cards") {
                        ForEach(viewModel.cards) { card in
                            Button(action: { viewModel.selectedTarget = .card(card.id) }) {
                                if case .card(let id) = viewModel.selectedTarget, id == card.id {
                                    Label(card.cardName, systemImage: "checkmark")
                                } else {
                                    Text(card.cardName)
                                }
                            }
                        }
                    }
                }

                Divider()
                Button(action: {}) { Text("New Account") }
                Button(action: {}) { Text("New Card") }
            } label: {
                let displayText: String = {
                    if let target = viewModel.selectedTarget {
                        switch target {
                        case .account(let id):
                            return viewModel.accounts.first { $0.id == id }?.accountName ?? "Account"
                        case .card(let id):
                            return viewModel.cards.first { $0.id == id }?.cardName ?? "Card"
                        }
                    }
                    return "Select target..."
                }()

                HStack {
                    Text(displayText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.down")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.xs)
            .background(AppColors.surface2)
            .cornerRadius(AppRadius.sm)
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
    }
}
