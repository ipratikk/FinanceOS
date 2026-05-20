import FinanceCore
import FinanceParsers
import FinanceUI
import SwiftUI

struct SupportedSourcesView: View {
    let viewModel: ImportViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FDSLabel("Supported Statements", style: .subheading)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(viewModel.supportedSources.enumerated()), id: \.offset) { _, source in
                    let isFullySupported = source.bankName == "ICICI" && source.sourceType == .bankAccount
                    let status = isFullySupported ? "" : " (coming soon)"
                    FDSLabel("• \(source.bankName) \(source.sourceType.rawValue)\(status)")
                        .caption()
                }
            }
            Divider()
            FDSLabel(
                "CSV and XLSX for CSV-based statements; "
                    + "TXT for delimited text (HDFC); PDF for scanned statements."
            )
                .caption()
        }
        .padding()
        .background(AppColors.surface2)
        .cornerRadius(AppRadius.sm)
    }
}

struct TargetSelectionSection: View {
    let viewModel: ImportViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    FDSLabel("Import To", style: .subheading)

                    FDSLabel("Select or create target", style: .hint)
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
                    Button(action: { viewModel.selectedTarget = nil }, label: {
                        FDSLabel("Clear")
                    })
                    Divider()
                }

                let accounts = viewModel.ledgers.filter { $0.kind == .bankAccount }
                if !accounts.isEmpty {
                    Menu("Accounts") {
                        ForEach(accounts) { account in
                            Button(action: { viewModel.selectedTarget = .ledger(account.id) }, label: {
                                if case let .ledger(id) = viewModel.selectedTarget, id == account.id {
                                    Label(account.displayName, systemImage: "checkmark")
                                } else {
                                    FDSLabel(account.displayName)
                                }
                            })
                        }
                    }
                }

                let cards = viewModel.ledgers.filter { $0.kind == .creditCard }
                if !cards.isEmpty {
                    Menu("Cards") {
                        ForEach(cards) { card in
                            Button(action: { viewModel.selectedTarget = .ledger(card.id) }, label: {
                                if case let .ledger(id) = viewModel.selectedTarget, id == card.id {
                                    Label(card.displayName, systemImage: "checkmark")
                                } else {
                                    FDSLabel(card.displayName)
                                }
                            })
                        }
                    }
                }

                Divider()
                Button(action: {}, label: { FDSLabel("New Account") })
                Button(action: {}, label: { FDSLabel("New Card") })
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
                    FDSLabel(displayText)
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
