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
                VStack(alignment: .leading, spacing: 4) {
                    Text(cardRow.title)
                    Text(cardRow.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Cards")
        }
        .task {
            await viewModel.loadCards()
        }
    }
}
