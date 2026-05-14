//
//  InstitutionsView.swift
//  FinanceOSMac
//
//  Created by Pratik Goel on 13/05/26.
//

import FinanceCore
import SwiftUI

struct InstitutionsView: View {
    @State private var viewModel: InstitutionsViewModel

    init(
        viewModel: InstitutionsViewModel
    ) {
        _viewModel = State(
            initialValue: viewModel
        )
    }

    var body: some View {
        NavigationStack {
            List(viewModel.institutions) { institution in
                Text(institution.name)
                    .contextMenu {
                        Button("Edit") {
                            viewModel.editingInstitution = institution
                        }
                        Button("Delete", role: .destructive) {
                            viewModel.editingInstitution = institution
                        }
                    }
            }
            .navigationTitle("Institutions")
        }
        .sheet(item: $viewModel.editingInstitution) { institution in
            InstitutionEditView(
                institution: institution,
                viewModel: viewModel
            )
        }
        .task {
            await viewModel.loadInstitutions()
        }
    }
}
