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
                listHeader

                VStack(spacing: 0) {
                    ForEach(Array(viewModel.banks.enumerated()), id: \.element.id) { index, bank in
                        bankRow(bank)
                        if index < viewModel.banks.count - 1 {
                            Divider()
                                .opacity(0.3)
                                .padding(.leading, 64)
                        }
                    }
                }
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.05), lineWidth: 0.5)
                        }
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.xl)
        }
    }

    private var listHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.tight) {
            Text("INSTITUTIONS")
                .labelSmall()
                .tracking(0.6)
                .foregroundStyle(.tertiary)
            Text("Banks")
                .displayMedium()
        }
    }

    private func bankRow(_ bank: Bank) -> some View {
        HStack(spacing: AppSpacing.md) {
            FDSMerchantAvatar(
                name: bank.name,
                symbol: "building.columns.fill",
                imageName: bank.logoAssetName,
                size: 36
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(bank.name)
                    .caption()
                Text(bank.providerType.rawValue.capitalized)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Menu {
                Button("Edit") { navigator.present(.bankEdit(bank)) }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 28, height: 28)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.compact)
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
        ScrollView {
            VStack(spacing: AppSpacing.compact) {
                ForEach(0 ..< 3, id: \.self) { _ in
                    skeletonRow
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.xl)
        }
    }

    private var skeletonRow: some View {
        HStack(spacing: AppSpacing.md) {
            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.04))
                    .frame(height: 11)
                    .frame(maxWidth: 160)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.04))
                    .frame(height: 9)
                    .frame(maxWidth: 110)
            }
            Spacer()
        }
        .padding(AppSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .fill(.ultraThinMaterial)
        }
    }
}
