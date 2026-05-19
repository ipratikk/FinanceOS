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
                        .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                    Text("Manage connected institutions")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(0.3)
                        .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
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
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(bank.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                        Text(bank.providerType.rawValue.capitalized)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        iconButton("pencil", color: Color(red: 0.518, green: 0.541, blue: 0.580)) {
                            navigator.present(.bankEdit(bank))
                        }
                        iconButton("trash", color: Color(red: 1.0, green: 0.27, blue: 0.23)) {
                            bankToDelete = bank
                            showDeleteConfirm = true
                        }
                    }
                }
                .padding(12)

                if !ledgers.isEmpty {
                    Divider().opacity(0.2)
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(ledgers) { ledger in
                            HStack(spacing: 8) {
                                Image(systemName: ledger.kind == .creditCard ? "creditcard.fill" : "banknote.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
                                Text(ledger.displayName)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
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
                        .foregroundColor(Color(red: 0.945, green: 0.953, blue: 0.965))
                    Text("Manage connected institutions")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(0.3)
                        .foregroundColor(Color(red: 0.741, green: 0.761, blue: 0.800))
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
                .fill(Color.white.opacity(0.04))
                .frame(width: 44, height: 44)

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
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                }
        }
    }
}
