import FinanceCore
import FinanceUI
import SwiftUI

struct TopMerchantsCard: View {
    let merchants: [MerchantSummary]
    @State private var period: Period = .monthly

    enum Period: String, CaseIterable {
        case monthly = "Monthly"
        case quarterly = "Quarterly"
    }

    var body: some View {
        FDSCard(cornerRadius: 16, padded: false) {
            VStack(alignment: .leading, spacing: 0) {
                headerRow
                Divider().opacity(0.12)
                merchantList
            }
        }
    }

    private var headerRow: some View {
        HStack {
            FDSLabel("TOP MERCHANTS")
                .font(AppTypography.captionSmSemibold)
                .tracking(1.0)
                .foregroundStyle(AppColors.Text.secondary)
            Spacer()
            periodPicker
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(Period.allCases, id: \.self) { opt in
                Button(action: { period = opt }, label: {
                    FDSLabel(opt.rawValue)
                        .font(AppTypography.captionSmSemibold)
                        .foregroundStyle(period == opt ? AppColors.Text.primary : AppColors.Text.tertiary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, 5)
                        .background(period == opt ? AppColors.Text.secondary.opacity(0.12) : Color.clear)
                        .cornerRadius(6)
                })
                .buttonStyle(.plain)
            }
        }
    }

    private var merchantList: some View {
        VStack(spacing: 0) {
            ForEach(Array(merchants.prefix(5).enumerated()), id: \.element.id) { idx, merchant in
                merchantRow(merchant)
                if idx < min(5, merchants.count) - 1 {
                    Divider().opacity(0.12).padding(.horizontal, AppSpacing.md)
                }
            }
        }
        .padding(.bottom, AppSpacing.sm)
    }

    private func merchantRow(_ merchant: MerchantSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: AppSpacing.sm) {
                merchantAvatar(merchant)
                VStack(alignment: .leading, spacing: 1) {
                    FDSLabel(merchant.name)
                        .font(AppTypography.bodySmMedium)
                        .foregroundStyle(AppColors.Text.primary)
                        .lineLimit(1)
                    FDSLabel("\(merchant.transactionCount) Transactions")
                        .font(AppTypography.captionSm)
                        .foregroundStyle(AppColors.Text.tertiary)
                }
                Spacer()
                FDSLabel(merchant.amountText)
                    .font(AppTypography.bodySmSemibold)
                    .foregroundStyle(AppColors.Text.primary)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColors.Text.secondary.opacity(0.08)).frame(height: 3)
                    Capsule()
                        .fill(AppColors.accentGreen)
                        .frame(width: geo.size.width * merchant.proportion, height: 3)
                }
            }
            .frame(height: 3)
            .padding(.leading, 44)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    private func merchantAvatar(_ merchant: MerchantSummary) -> some View {
        ZStack {
            Circle()
                .fill(avatarColor(for: merchant.name).opacity(0.2))
                .frame(width: 36, height: 36)
            FDSLabel(merchant.initials)
                .font(AppTypography.captionSmSemibold)
                .foregroundStyle(avatarColor(for: merchant.name))
        }
    }

    private func avatarColor(for name: String) -> Color {
        let colors: [Color] = [
            AppColors.accentGreen,
            AppColors.accentBlue,
            AppColors.accentPurple,
            AppColors.accentOrange,
            .cyan,
            .pink
        ]
        return colors[abs(name.hashValue) % colors.count]
    }
}
