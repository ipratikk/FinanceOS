import FinanceCore
import SwiftUI

struct BanksView: View {
    @State private var viewModel: BanksViewModel

    init(viewModel: BanksViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            if viewModel.banks.isEmpty, !viewModel.isLoading {
                emptyState
            } else if viewModel.isLoading {
                loadingState
            } else {
                banksList
            }
        }
        .navigationTitle("Banks")
        .sheet(item: $viewModel.editingBank) { bank in
            BankEditView(bank: bank, viewModel: viewModel)
        }
        .task {
            await viewModel.loadBanks()
        }
    }

    var banksList: some View {
        List(viewModel.banks, id: \.id) { bank in
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bank.name)
                        .monoAmount()

                    Text(bank.providerType.rawValue.uppercased())
                        .labelSmall()
                        .foregroundColor(AppColors.textTertiary)
                }

                Spacer()

                Menu {
                    Button("Edit") { viewModel.editingBank = bank }
                    Button("Delete", role: .destructive) { viewModel.editingBank = bank }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .listRowBackground(AppColors.surface)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            .listRowSeparator(.hidden)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    viewModel.editingBank = bank
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .listStyle(.plain)
        .background(AppColors.base)
        .scrollContentBackground(.hidden)
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.columns")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(AppColors.textTertiary)

            VStack(spacing: 8) {
                Text("No Banks")
                    .headingSmall()

                Text("Add a bank when importing your first statement")
                    .caption()
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    var loadingState: some View {
        VStack(spacing: 8) {
            ForEach(0 ..< 3, id: \.self) { _ in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.surface2)
                            .frame(height: 12)
                            .frame(maxWidth: 120)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppColors.surface2)
                            .frame(height: 10)
                            .frame(maxWidth: 80)
                    }

                    Spacer()
                }
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .cornerRadius(AppRadius.md)
            }
        }
        .padding(AppSpacing.md)
    }
}
