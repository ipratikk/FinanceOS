import FinanceCore
import SwiftUI

struct CardsView: View {
    @State private var viewModel: CardsViewModel
    @State private var selectedCardId: UUID?
    @State private var cardPendingDelete: Ledger?
    let selection: NavigationItem?
    private let transactionRepository: any TransactionRepository
    private let ledgerRepository: any LedgerRepository

    init(
        viewModel: CardsViewModel,
        transactionRepository: any TransactionRepository,
        ledgerRepository: any LedgerRepository,
        selection: NavigationItem? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.transactionRepository = transactionRepository
        self.ledgerRepository = ledgerRepository
        self.selection = selection
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
        .sheet(item: $viewModel.editingCard) { ledger in
            CardEditView(card: ledger, viewModel: viewModel)
        }
        .alert(
            "Delete \"\(cardPendingDelete?.displayName ?? "")\"?",
            isPresented: Binding(
                get: { cardPendingDelete != nil },
                set: { if !$0 { cardPendingDelete = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { cardPendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let ledger = cardPendingDelete {
                    cardPendingDelete = nil
                    Task { await viewModel.deleteCard(id: ledger.id) }
                }
            }
        } message: {
            Text(
                "This will permanently delete this card and all associated transactions. This cannot be undone."
            )
        }
        .alert("Delete Failed", isPresented: Binding(
            get: { viewModel.deleteError != nil },
            set: { if !$0 { viewModel.deleteError = nil } }
        )) {
            Button("OK") { viewModel.deleteError = nil }
        } message: {
            if let error = viewModel.deleteError {
                Text(error)
            }
        }
        .task {
            await viewModel.loadCards()
        }
        .id(selection)
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
                            cardRowView(cardRow.card)
                        }
                        .listRowBackground(AppColors.surface)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                cardPendingDelete = cardRow.card
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button("Edit") { viewModel.editingCard = cardRow.card }
                            Button("Delete", role: .destructive) {
                                cardPendingDelete = cardRow.card
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
            if let ledger = viewModel.cardRows.first(where: { $0.card.id == cardId })?.card {
                CardTransactionsView(
                    ledger: ledger,
                    viewModel: CardTransactionsViewModel(
                        transactionRepository: transactionRepository
                    )
                )
                .navigationTitle(ledger.displayName)
                .onAppear { selectedCardId = cardId }
            }
        }
    }

    private var groupedCardsByBank: [String: [CardsViewModel.CardRow]] {
        Dictionary(grouping: viewModel.cardRows) { cardRow in
            viewModel.banks.first { $0.id == cardRow.card.bankId }?.name ?? "Unknown"
        }
    }

    func cardRowView(_ ledger: Ledger) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(ledger.nickname.isEmpty ? ledger.displayName : ledger.nickname)
                    .monoAmount()

                Text((ledger.cardType ?? "").uppercased())
                    .labelSmall()
                    .foregroundColor(AppColors.textTertiary)
            }

            Spacer()

            Text("••••\(ledger.last4)")
                .monoAmountSmall()
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
                    .headingSmall()

                Text("Import a statement to get started")
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
