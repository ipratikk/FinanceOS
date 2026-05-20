import FinanceCore
import FinanceUI
import SwiftUI

struct BanksView: View {
    @State private var viewModel: BanksViewModel
    @Environment(AppNavigator.self) private var navigator
    @State private var bankToDelete: Bank?
    @State private var showDeleteConfirm = false

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
        .task { await viewModel.loadBanks() }
        .alert("Delete Bank?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let bank = bankToDelete {
                    Task { await viewModel.deleteBank(id: bank.id) }
                }
            }
        } message: {
            Text("This will delete this bank and all associated cards, accounts, and transactions.")
        }
    }

    private var banksList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Banks")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(DesignTokens.Text.primary)
                    Text("Manage connected institutions")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(0.3)
                        .foregroundColor(DesignTokens.Text.secondary)
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
                        Text(bank.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(DesignTokens.Text.primary)
                        Text(bank.providerType.rawValue.capitalized)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(DesignTokens.Text.secondary)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        iconButton("pencil", color: DesignTokens.Text.tertiary) {
                            navigator.present(.bankEdit(bank))
                        }
                        iconButton("trash", color: DesignTokens.System.red) {
                            bankToDelete = bank
                            showDeleteConfirm = true
                        }
                    }
                }
                .padding(12)

                if !ledgers.isEmpty {
                    Divider().opacity(DesignTokens.Opacity.low)
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(ledgers) { ledger in
                            HStack(spacing: 8) {
                                Image(systemName: ledger.kind == .creditCard ? "creditcard.fill" : "banknote.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(DesignTokens.Text.secondary)
                                Text(ledger.displayName)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(DesignTokens.Text.secondary)
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
                .font(.system(size: 12, weight: .semibold))
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
                    Text("Banks")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(DesignTokens.Text.primary)
                    Text("Manage connected institutions")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(0.3)
                        .foregroundColor(DesignTokens.Text.secondary)
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
                .fill(DesignTokens.Background.surfaceGlassThin)
                .frame(width: AppSpacing.hitTarget, height: AppSpacing.hitTarget)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(DesignTokens.Background.surfaceGlassThin)
                    .frame(height: 13)
                    .frame(maxWidth: 180)
                RoundedRectangle(cornerRadius: 3)
                    .fill(DesignTokens.Background.surfaceGlassThin)
                    .frame(height: 11)
                    .frame(maxWidth: 120)
            }
            Spacer()
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Background.surfaceGlass)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(DesignTokens.Background.surfaceGlassMid, lineWidth: 1)
                }
        }
    }
}
