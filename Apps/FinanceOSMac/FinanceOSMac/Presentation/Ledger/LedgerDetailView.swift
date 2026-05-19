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

                        if ledger.kind == .creditCard {
                            // TODO: Add utilization section
                        }

                        metricsSection

                        recentActivitySection
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 24)
                    .frame(maxWidth: 1080)
                }
                .background(AppColors.base)
            } else if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading…")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.base)
            } else {
                VStack {
                    Text("Ledger not found")
                        .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
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
                            network: ledger.cardType?.uppercased() ?? "CARD",
                            last4: ledger.last4
                        )
                        .frame(width: 76, height: 48)
                    } else {
                        FDSBankMark(bank?.bank ?? .hdfc)
                            .frame(width: 44, height: 44)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(ledger.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))

                        HStack(spacing: 4) {
                            Text(ledger.kind.displayName.uppercased())
                                .font(.system(size: 11, weight: .semibold))
                            if !ledger.last4.isEmpty {
                                Text("•••• \(ledger.last4)")
                                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                            }
                        }
                        .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
                    }

                    Spacer()
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Balance")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
                        Text(formatBalance(ledger.closingBalance ?? 0))
                            .font(.system(size: 28, weight: .semibold, design: .default))
                            .monospacedDigit()
                            .foregroundColor(Color(red: 0.19, green: 0.82, blue: 0.35))
                    }
                    Spacer()
                }
            }
            .padding(20)
        }
    }

    private func utilizationSection(_ ledger: Ledger, limit: Int64) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            let balance = ledger.closingBalance ?? 0
            let utilization = limit > 0 ? Double(balance) / Double(limit) : 0
            let percent = Int(utilization * 100)

            FDSCard(cornerRadius: 12, padded: false) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Credit Utilization")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                        Spacer()
                        Text("\(percent)%")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(percent > 80 ? Color(red: 1.0, green: 0.27, blue: 0.23) : Color(
                                red: 0.19,
                                green: 0.82,
                                blue: 0.35
                            ))
                    }

                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(percent > 80 ? Color(red: 1.0, green: 0.27, blue: 0.23) : Color(
                                    red: 0.19,
                                    green: 0.82,
                                    blue: 0.35
                                ))
                                .frame(width: max(0, min(1, utilization)) * 260)
                        }
                }
                .padding(12)
            }
        }
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))

            HStack(spacing: 12) {
                metricCard("Income", value: "₹0.00", color: Color(red: 0.19, green: 0.82, blue: 0.35))
                metricCard("Spending", value: "₹0.00", color: Color(red: 1.0, green: 0.27, blue: 0.23))
                metricCard("Transactions", value: "0", color: Color(red: 0.518, green: 0.541, blue: 0.580))
            }
        }
    }

    private func metricCard(_ label: String, value: String, color: Color) -> some View {
        FDSCard(cornerRadius: 12, padded: false) {
            VStack(alignment: .leading, spacing: 8) {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.2)
                    .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))

                Text(value)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .monospacedDigit()
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))

            FDSCard(cornerRadius: 12, padded: false) {
                VStack(spacing: 0) {
                    Text("No transactions yet")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
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
