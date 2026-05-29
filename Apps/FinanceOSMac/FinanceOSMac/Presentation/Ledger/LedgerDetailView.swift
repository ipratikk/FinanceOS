import FinanceCore
import FinanceUI
import SwiftUI

struct LedgerDetailView: View {
    @Bindable var viewModel: LedgerDetailViewModel
    @Environment(AppNavigator.self) private var navigator

    var body: some View {
        Group {
            if let ledger = viewModel.ledger {
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
            } else if viewModel.isLoading {
                VStack(spacing: AppSpacing.sm) {
                    ProgressView()
                        .controlSize(.small)
                    FDSLabel("Loading…")
                        .font(AppTypography.captionSmMedium)
                        .foregroundColor(AppColors.Text.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.base)
            } else {
                VStack {
                    FDSLabel("Ledger not found")
                        .foregroundColor(AppColors.Text.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.base)
            }
        }
        .navigationTitle(viewModel.navigationTitle)
        .task {
            await viewModel.load()
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
                        FDSBankMark(viewModel.bank?.bank ?? .hdfc)
                            .frame(width: AppSpacing.hitTarget, height: AppSpacing.hitTarget)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        FDSLabel(ledger.displayName)
                            .font(AppTypography.headingSmall)
                            .foregroundColor(AppColors.Text.primary)

                        HStack(spacing: 4) {
                            FDSLabel(ledger.kind.displayName.uppercased())
                                .font(AppTypography.captionSmSemibold)
                            if !ledger.last4.isEmpty {
                                FDSLabel("•••• \(ledger.last4)")
                                    .font(AppTypography.captionSm)
                            }
                        }
                        .foregroundColor(AppColors.Text.secondary)
                    }

                    Spacer()
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        FDSLabel("Balance")
                            .font(AppTypography.captionSmMedium)
                            .foregroundColor(AppColors.Text.secondary)
                        FDSLabel(viewModel.balanceText)
                            .font(AppTypography.headingLg)
                            .monospacedDigit()
                            .foregroundColor(AppColors.System.green)
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
                        FDSLabel("Credit Utilization")
                            .font(AppTypography.bodySmSemibold)
                            .foregroundColor(AppColors.Text.primary)
                        Spacer()
                        FDSLabel("\(percent)%")
                            .font(AppTypography.bodySmSemibold)
                            .foregroundColor(percent > 80 ? AppColors.System.red : AppColors.System.green)
                    }

                    Capsule()
                        .fill(AppColors.Border.strong)
                        .frame(height: 6)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(percent > 80 ? AppColors.System.red : AppColors.System.green)
                                .frame(width: max(0, min(1, utilization)) * 260)
                        }
                }
                .padding(AppSpacing.sm)
            }
        }
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            FDSLabel("Statistics")
                .font(AppTypography.headingSmall)
                .foregroundColor(AppColors.Text.primary)

            HStack(spacing: AppSpacing.sm) {
                metricCard("Income", value: "₹0.00", color: AppColors.System.green)
                metricCard("Spending", value: "₹0.00", color: AppColors.System.red)
                metricCard("Transactions", value: "0", color: AppColors.Text.tertiary)
            }
        }
    }

    private func metricCard(_ label: String, value: String, color: Color) -> some View {
        FDSCard(cornerRadius: 12, padded: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                FDSLabel(label.uppercased())
                    .font(AppTypography.captionSmSemibold)
                    .tracking(0.2)
                    .foregroundColor(AppColors.Text.secondary)

                FDSLabel(value)
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
            FDSLabel("Recent Activity")
                .font(AppTypography.headingSmall)
                .foregroundColor(AppColors.Text.primary)

            FDSCard(cornerRadius: 12, padded: false) {
                VStack(spacing: 0) {
                    FDSLabel("No transactions yet")
                        .font(AppTypography.bodySm)
                        .foregroundColor(AppColors.Text.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(AppSpacing.lg)
                }
            }
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

// Preview removed — inject LedgerDetailViewModel from call site
