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
        .navigationTitle("Banks")
        .task {
            await viewModel.loadBanks()
        }
    }

    private var banksList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                VStack(alignment: .leading, spacing: AppSpacing.compact) {
                    FDSLabel("INSTITUTIONS", style: .labelSmall)
                    FDSLabel("Banks", style: .displayMedium)
                }
                .padding(.horizontal, AppSpacing.xl)

                VStack(spacing: AppSpacing.md) {
                    ForEach(viewModel.banks) { bank in
                        bankRow(bank)
                    }
                }
                .padding(.horizontal, AppSpacing.xl)

                Spacer()
            }
            .padding(.vertical, AppSpacing.xl)
        }
    }

    private func bankRow(_ bank: Bank) -> some View {
        let ledgers = viewModel.ledgersByBank[bank.id] ?? []
        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.lg) {
                FDSImage(
                    imageName: bank.logoAssetName,
                    fallbackSymbol: "building.columns.fill",
                    height: 48,
                    width: 100
                )

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    FDSLabel(bank.name, style: .bodyLarge)
                    FDSLabel(bank.providerType.rawValue.capitalized, style: .caption, color: .secondary)
                }

                Spacer()

                Menu {
                    Button("Edit") { navigator.present(.bankEdit(bank)) }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
            }

            if !ledgers.isEmpty {
                Divider().opacity(0.3)
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    ForEach(ledgers) { ledger in
                        HStack(spacing: AppSpacing.compact) {
                            Image(systemName: ledger.kind == .creditCard ? "creditcard.fill" : "banknote.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                            FDSLabel(ledger.displayName, style: .caption, color: .secondary)
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.05), lineWidth: 0.5)
                }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "building.columns")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.tertiary)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: AppSpacing.tight) {
                Text("No Banks")
                    .bodyLarge()
                Text("Add a bank when importing your first statement")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingState: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                VStack(alignment: .leading, spacing: AppSpacing.compact) {
                    FDSLabel("INSTITUTIONS", style: .labelSmall)
                    FDSLabel("Banks", style: .displayMedium)
                }
                .padding(.horizontal, AppSpacing.xl)

                VStack(spacing: AppSpacing.md) {
                    ForEach(0 ..< 3, id: \.self) { _ in
                        skeletonRow
                    }
                }
                .padding(.horizontal, AppSpacing.xl)

                Spacer()
            }
            .padding(.vertical, AppSpacing.xl)
        }
    }

    private var skeletonRow: some View {
        HStack(spacing: AppSpacing.lg) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.04))
                .frame(width: 100, height: 48)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.04))
                    .frame(height: 13)
                    .frame(maxWidth: 180)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.04))
                    .frame(height: 11)
                    .frame(maxWidth: 120)
            }
            Spacer()
        }
        .padding(AppSpacing.lg)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.05), lineWidth: 0.5)
                }
        }
    }
}
