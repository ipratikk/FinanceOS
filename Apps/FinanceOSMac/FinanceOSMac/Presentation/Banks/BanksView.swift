//
//  BanksView.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 15/05/26.
//

import FinanceCore
import SwiftUI

struct BanksView: View {
    @State private var viewModel: BanksViewModel

    init(
        viewModel: BanksViewModel
    ) {
        _viewModel = State(
            initialValue: viewModel
        )
    }

    var body: some View {
        NavigationStack {
            List(viewModel.banks) { bank in
                Text(bank.name)
                    .contextMenu {
                        Button("Edit") {
                            viewModel.editingBank = bank
                        }
                        Button("Delete", role: .destructive) {
                            viewModel.editingBank = bank
                        }
                    }
            }
            .navigationTitle("Banks")
        }
        .sheet(item: $viewModel.editingBank) { bank in
            BankEditView(
                bank: bank,
                viewModel: viewModel
            )
        }
        .task {
            await viewModel.loadBanks()
        }
    }
}
