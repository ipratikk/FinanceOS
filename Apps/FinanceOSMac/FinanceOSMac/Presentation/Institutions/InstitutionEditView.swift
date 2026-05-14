import FinanceCore
import SwiftUI

struct InstitutionEditView: View {
    let institution: Institution
    let viewModel: InstitutionsViewModel
    @State private var name: String
    @Environment(\.dismiss) var dismiss

    @State private var showDeleteConfirm = false

    init(institution: Institution, viewModel: InstitutionsViewModel) {
        self.institution = institution
        self.viewModel = viewModel
        _name = State(initialValue: institution.name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Institution Details") {
                    TextField("Name", text: $name)
                }

                Section {
                    Button("Delete Institution", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
            .navigationTitle("Edit Institution")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        Task {
                            let updated = Institution(id: institution.id, name: name)
                            await viewModel.updateInstitution(updated)
                        }
                    }
                }
            }
        }
        .alert("Delete Institution?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteInstitution(id: institution.id)
                    dismiss()
                }
            }
        } message: {
            Text(
                "This will permanently delete this institution and all associated cards, accounts, and transactions. This cannot be undone."
            )
        }
    }
}
