import FinanceCore
import FinanceUI
import SwiftUI

struct LedgerDetailView: View {
    let ledgerId: UUID
    @Environment(AppNavigator.self) private var navigator
    @State private var ledger: Ledger?
    @State private var bank: Bank?
    @State private var isLoading = true

    private let appContainer = AppContainer.shared

    var body: some View {
        Group {
            if let ledger {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        heroCard(ledger)

                        if ledger.kind == .creditCard { EmptyView() }

                        metricsSection

                        recentActivitySection
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 24)
                    .frame(maxWidth: 1080)
                }
                .background(AppColors.base)
            } else if isLoading {
                VStack(spacing: AppSpacing.sm) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading…")
                        .font(AppTypography.captionSmMedium)
                        .foregroundColor(DesignTokens.Text.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.base)
            } else {
                VStack {
                    Text("Ledger not found")
                        .foregroundColor(DesignTokens.Text.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.base)
            }
        }
        .navigationTitle(ledger?.displayName ?? "Ledger")
        .task {
            await loadLedger()
        }
    }

    private func heroCard(_ ledger: Ledger) -> some View {
        FDSCard(cornerRadius: 18, padded: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 20) {
                    if ledger.kind == .creditCard {
                        FDSCardArt(
                            ledger.displayName,
                            network: ledger.cardType?.rawValue.uppercased() ?? "CARD",
                            last4: ledger.last4
                        )
                        .frame(width: 76, height: 48)
                    } else {
                        FDSBankMark(bank?.bank ?? .hdfc)
                            .frame(width: AppSpacing.hitTarget, height: AppSpacing.hitTarget)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(ledger.displayName)
                            .font(AppTypography.headingSmall)
                            .foregroundColor(DesignTokens.Text.primary)

                        HStack(spacing: 4) {
                            Text(ledger.kind.displayName.uppercased())
                                .font(AppTypography.captionSmSemibold)
                            if !ledger.last4.isEmpty {
                                Text("•••• \(ledger.last4)")
                                    .font(AppTypography.captionSm)
                            }
                        }
                        .foregroundColor(DesignTokens.Text.secondary)
                    }

                    Spacer()
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Balance")
                            .font(AppTypography.captionSmMedium)
                            .foregroundColor(DesignTokens.Text.secondary)
                        Text(formatBalance(ledger.closingBalance ?? 0))
                            .font(.system(size: 28, weight: .semibold, design: .default))
                            .monospacedDigit()
                            .foregroundColor(DesignTokens.System.green)
                    }
                    Spacer()
                }
            }
            .padding(AppSpacing.lg)
        }
    }

    private func utilizationSection(_ ledger: Ledger, limit: Int64) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            let balance = ledger.closingBalance ?? 0
            let utilization = limit > 0 ? Double(balance) / Double(limit) : 0
            let percent = Int(utilization * 100)

            FDSCard(cornerRadius: 12, padded: false) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text("Credit Utilization")
                            .font(AppTypography.bodySmSemibold)
                            .foregroundColor(DesignTokens.Text.primary)
                        Spacer()
                        Text("\(percent)%")
                            .font(AppTypography.bodySmSemibold)
                            .foregroundColor(percent > 80 ? DesignTokens.System.red : DesignTokens.System.green)
                    }

                    Capsule()
                        .fill(DesignTokens.Border.strong)
                        .frame(height: 6)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(percent > 80 ? DesignTokens.System.red : DesignTokens.System.green)
                                .frame(width: max(0, min(1, utilization)) * 260)
                        }
                }
                .padding(AppSpacing.sm)
            }
        }
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Statistics")
                .font(AppTypography.headingSmall)
                .foregroundColor(DesignTokens.Text.primary)

            HStack(spacing: AppSpacing.sm) {
                metricCard("Income", value: "₹0.00", color: DesignTokens.System.green)
                metricCard("Spending", value: "₹0.00", color: DesignTokens.System.red)
                metricCard("Transactions", value: "0", color: DesignTokens.Text.tertiary)
            }
        }
    }

    private func metricCard(_ label: String, value: String, color: Color) -> some View {
        FDSCard(cornerRadius: 12, padded: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.2)
                    .foregroundColor(DesignTokens.Text.secondary)

                Text(value)
                    .font(AppTypography.headingSmall)
                    .monospacedDigit()
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.sm)
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(DesignTokens.Text.primary)

            FDSCard(cornerRadius: 12, padded: false) {
                VStack(spacing: 0) {
                    Text("No transactions yet")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(DesignTokens.Text.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(24)
                }
            }
        }
    }

    private func formatBalance(_ minorUnits: Int64) -> String {
        let amount = Double(minorUnits) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.currencySymbol = "₹"
        return formatter.string(from: NSNumber(value: amount)) ?? "₹0.00"
    }

    private func loadLedger() async {
        do {
            ledger = try await appContainer.ledgerRepository.fetchLedger(id: ledgerId)
            if let ledger {
                let banks = try await appContainer.bankRepository.fetchBanks()
                bank = banks.first { $0.id == ledger.bankId }
            }
            isLoading = false
        } catch {
            isLoading = false
        }
    }
}

extension LedgerKind {
    var displayName: String {
        switch self {
        case .bankAccount: "Bank Account"
        case .creditCard: "Credit Card"
        case .loan: "Loan"
        case .wallet: "Wallet"
        case .crypto: "Crypto"
        case .investment: "Investment"
        }
    }
}

#Preview {
    LedgerDetailView(ledgerId: UUID())
        .environment(AppNavigator())
}
