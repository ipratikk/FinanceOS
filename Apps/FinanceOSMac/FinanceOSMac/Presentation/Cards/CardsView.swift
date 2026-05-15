import FinanceCore
import SwiftUI

struct CardsView: View {
    @State private var viewModel: CardsViewModel
    @State private var selectedCardId: UUID?
    private let transactionRepository: any TransactionRepository
    private let accountRepository: any AccountRepository

    init(
        viewModel: CardsViewModel,
        transactionRepository: any TransactionRepository,
        accountRepository: any AccountRepository
    ) {
        _viewModel = State(initialValue: viewModel)
        self.transactionRepository = transactionRepository
        self.accountRepository = accountRepository
    }

    var body: some View {
        NavigationStack {
            if viewModel.cardRows.isEmpty, !viewModel.isLoading {
                emptyState
            } else if viewModel.isLoading {
                loadingState
            } else {
                cardsList
            }
        }
        .navigationTitle("Cards")
        .sheet(item: $viewModel.editingCard) { card in
            CardEditView(card: card, viewModel: viewModel)
        }
        .task {
            await viewModel.loadCards()
        }
    }

    var cardsList: some View {
        List {
            ForEach(
                groupedCardsByBank.sorted(by: { $0.key < $1.key }),
                id: \.key
            ) { bankName, cardRows in
                Section(bankName) {
                    ForEach(cardRows, id: \.card.id) { cardRow in
                        NavigationLink(value: cardRow.card.id) {
                            cardRowView(cardRow)
                        }
                        .listRowBackground(AppColors.surface)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.editingCard = cardRow.card
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button("Edit") { viewModel.editingCard = cardRow.card }
                            Button("Delete", role: .destructive) {
                                viewModel.editingCard = cardRow.card
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(AppColors.base)
        .scrollContentBackground(.hidden)
        .navigationDestination(for: UUID.self) { cardId in
            if let card = viewModel.cardRows.first(where: { $0.card.id == cardId })?.card {
                CardTransactionsView(
                    card: card,
                    viewModel: CardTransactionsViewModel(
                        transactionRepository: transactionRepository,
                        accountRepository: accountRepository
                    )
                )
                .navigationTitle(card.cardName)
                .onAppear { selectedCardId = cardId }
            }
        }
    }

    private var groupedCardsByBank: [String: [CardsViewModel.CardRow]] {
        Dictionary(grouping: viewModel.cardRows) { cardRow in
            viewModel.banks.first { $0.id == cardRow.card.bankId }?.name ?? "Unknown"
        }
    }

    func cardRowView(_ cardRow: CardsViewModel.CardRow) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(cardRow.card.nickname.isEmpty ? cardRow.card.cardName : cardRow.card.nickname)
                    .font(.system(size: 14, weight: .semibold))

                Text(cardRow.card.cardType.rawValue.uppercased())
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(AppColors.textTertiary)
            }

            Spacer()

            Text("••••\(cardRow.card.cardLast4)")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(AppColors.accent)
        }
        .padding(AppSpacing.sm)
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(AppColors.textTertiary)

            VStack(spacing: 8) {
                Text("No Cards")
                    .font(.system(size: 16, weight: .semibold))

                Text("Import a statement to get started")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    var loadingState: some View {
        VStack(spacing: 8) {
            ForEach(0 ..< 3, id: \.self) { _ in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppColors.surface2)
                        .frame(width: 40, height: 40)

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
