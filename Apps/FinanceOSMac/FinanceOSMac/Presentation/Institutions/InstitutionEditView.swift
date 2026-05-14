import FinanceCore
import SwiftUI

struct InstitutionEditView: View {
    @Bindable var institution: Institution
    let viewModel: InstitutionsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Institution Details") {
                    TextField("Name", text: $institution.name)
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
                            await viewModel.updateInstitution(institution)
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
                }
            }
        } message: {
            Text("This will permanently delete this institution and all associated cards, accounts, and transactions. This cannot be undone.")
        }
    }
}
