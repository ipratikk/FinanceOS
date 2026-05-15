//
//  CardsView.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 13/05/26.
//

import FinanceCore
import SwiftUI

struct CardsView: View {
    @State private var viewModel: CardsViewModel
    @State private var selectedCardId: UUID?
    private let appContainer = AppContainer.shared

    init(
        viewModel: CardsViewModel
    ) {
        _viewModel = State(
            initialValue: viewModel
        )
    }

    var body: some View {
        NavigationStack {
            List(viewModel.cardRows) { cardRow in
                NavigationLink(value: cardRow.card.id) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cardRow.title)
                        Text(cardRow.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .contextMenu {
                    Button("Edit") {
                        viewModel.editingCard = cardRow.card
                    }
                    Button("Delete", role: .destructive) {
                        viewModel.editingCard = cardRow.card
                    }
                }
            }
            .navigationDestination(for: UUID.self) { cardId in
                if let card = viewModel.cardRows.first(where: { $0.card.id == cardId })?.card {
                    CardTransactionsView(
                        card: card,
                        viewModel: CardTransactionsViewModel(
                            transactionRepository: appContainer.transactionRepository,
                            accountRepository: appContainer.accountRepository
                        )
                    )
                    .navigationTitle(card.cardName)
                    .onAppear {
                        selectedCardId = cardId
                    }
                }
            }
        }
        .navigationTitle("Cards")
        .sheet(item: $viewModel.editingCard) { card in
            CardEditView(
                card: card,
                viewModel: viewModel
            )
        }
        .task {
            await viewModel.loadCards()
        }
    }
}
