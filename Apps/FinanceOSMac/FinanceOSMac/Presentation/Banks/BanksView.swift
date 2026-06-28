import FinanceCore
import FinanceUI
import SwiftUI

struct BanksView: View {
    @State private var viewModel: BanksViewModel
    @Environment(AppNavigator.self) private var navigator

    init(viewModel: BanksViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.banks.isEmpty, !viewModel.isLoading {
                emptyState
            } else if viewModel.isLoading {
                loadingState
            } else {
                banksList
            }
        }
        .background(AppColors.base)
        .task { await viewModel.loadBanks() }
    }

    private var banksList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    FDSLabel("Banks")
                        .font(AppTypography.headingLg)
                        .foregroundColor(AppColors.Text.primary)
                    FDSLabel("Manage connected institutions")
                        .font(AppTypography.captionSmMedium)
                        .tracking(0.2)
                        .foregroundColor(AppColors.Text.secondary)
                }
                .padding(.horizontal, 32)

                VStack(spacing: 12) {
                    ForEach(viewModel.banks) { bank in
                        bankRow(bank)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .padding(.vertical, 24)
        }
    }

    private func bankRow(_ bank: Bank) -> some View {
        let ledgers = viewModel.ledgersByBank[bank.id] ?? []
        return FDSCard(cornerRadius: 12, padded: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 16) {
                    FDSBankMark(bank.bank)
                        .frame(width: AppSpacing.hitTarget, height: AppSpacing.hitTarget)

                    VStack(alignment: .leading, spacing: 2) {
                        FDSLabel(bank.name)
                            .font(AppTypography.bodySmSemibold)
                            .foregroundColor(AppColors.Text.primary)
                        FDSLabel(bank.providerType.rawValue.capitalized)
                            .font(AppTypography.captionSmMedium)
                            .foregroundColor(AppColors.Text.secondary)
                    }

                    Spacer()

                    iconButton("pencil", color: AppColors.Text.tertiary) {
                        navigator.present(.bankEdit(bank))
                    }
                }
                .padding(AppSpacing.xs)

                if !ledgers.isEmpty {
                    Divider().opacity(AppColors.Opacity.low)
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(ledgers) { ledger in
                            HStack(spacing: 8) {
                                Image(systemName: ledger.kind == .creditCard ? "creditcard.fill" : "banknote.fill")
                                    .font(AppTypography.captionSmSemibold)
                                    .foregroundColor(AppColors.Text.secondary)
                                FDSLabel(ledger.displayName)
                                    .font(AppTypography.captionSmMedium)
                                    .foregroundColor(AppColors.Text.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private func iconButton(
        _ symbol: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(AppTypography.captionSmSemibold)
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(Circle().fill(color.opacity(0.15)))
        }
        .buttonStyle(.plain)
        .frame(minWidth: 32, minHeight: 32)
        .contentShape(Rectangle())
    }

    private var emptyState: some View {
        FDSEmptyState(
            symbol: "building.columns",
            title: "No Banks",
            subtitle: "Add a bank when importing your first statement"
        )
    }

    private var loadingState: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    FDSLabel("Banks")
                        .font(AppTypography.headingLg)
                        .foregroundColor(AppColors.Text.primary)
                    FDSLabel("Manage connected institutions")
                        .font(AppTypography.captionSmMedium)
                        .tracking(0.2)
                        .foregroundColor(AppColors.Text.secondary)
                }
                .padding(.horizontal, 32)

                VStack(spacing: 12) {
                    ForEach(0 ..< 3, id: \.self) { _ in
                        skeletonRow
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .padding(.vertical, 24)
        }
    }

    private var skeletonRow: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 6)
                .fill(AppColors.Glass.thinTint)
                .frame(width: AppSpacing.hitTarget, height: AppSpacing.hitTarget)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppColors.Glass.thinTint)
                    .frame(height: 13)
                    .frame(maxWidth: 180)
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppColors.Glass.thinTint)
                    .frame(height: 11)
                    .frame(maxWidth: 120)
            }
            Spacer()
        }
        .padding(AppSpacing.xs)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.Glass.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AppColors.Glass.midTint, lineWidth: 1)
                }
        }
    }
}
