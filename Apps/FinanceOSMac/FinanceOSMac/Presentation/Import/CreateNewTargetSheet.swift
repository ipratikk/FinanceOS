import FinanceCore
import SwiftUI

struct CreateNewTargetSheet: View {
    @Binding var name: String
    @Binding var institutionID: UUID?
    let isCard: Bool
    let institutions: [Institution]
    let onCancel: () -> Void
    let onCreate: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $name)
                }

                if !institutions.isEmpty {
                    Section("Institution") {
                        Picker("Institution", selection: $institutionID) {
                            Text("Select Institution").tag(UUID?.none)
                            ForEach(institutions) { institution in
                                Text(institution.name).tag(UUID?(institution.id))
                            }
                        }
                    }
                }
            }
            .navigationTitle(isCard ? "Create New Card" : "Create New Account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || institutionID == nil)
                }
            }
        }
    }
}
