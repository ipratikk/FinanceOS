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

                let accounts = viewModel.ledgers.filter { $0.kind == .bankAccount }
                if !accounts.isEmpty {
                    Menu("Accounts") {
                        ForEach(accounts) { account in
                            Button(action: { viewModel.selectedTarget = .ledger(account.id) }) {
                                if case let .ledger(id) = viewModel.selectedTarget, id == account.id {
                                    Label(account.displayName, systemImage: "checkmark")
                                } else {
                                    Text(account.displayName)
                                }
                            }
                        }
                    }
                }

                let cards = viewModel.ledgers.filter { $0.kind == .creditCard }
                if !cards.isEmpty {
                    Menu("Cards") {
                        ForEach(cards) { card in
                            Button(action: { viewModel.selectedTarget = .ledger(card.id) }) {
                                if case let .ledger(id) = viewModel.selectedTarget, id == card.id {
                                    Label(card.displayName, systemImage: "checkmark")
                                } else {
                                    Text(card.displayName)
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
                        if case let .ledger(id) = target {
                            return viewModel.ledgers.first { $0.id == id }?.displayName ?? "Ledger"
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
