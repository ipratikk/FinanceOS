import FinanceCore
import FinanceIntelligence
import FinanceUI
import SwiftUI

// MARK: - ViewModel

@MainActor
@Observable
final class PersonsViewModel {
    private let repo: any IntelligencePersonRepository
    var persons: [Person] = []
    var isLoading = false
    var personToEdit: Person?
    var personToDelete: Person?
    var errorMessage: String?

    init(repo: any IntelligencePersonRepository) {
        self.repo = repo
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            persons = try await repo.fetchAll()
                .sorted { $0.canonicalName < $1.canonicalName }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ person: Person) async {
        do {
            try await repo.delete(id: person.id)
            persons.removeAll { $0.id == person.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func update(_ person: Person) async {
        do {
            try await repo.update(person)
            if let idx = persons.firstIndex(where: { $0.id == person.id }) {
                persons[idx] = person
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - List View

struct PersonsView: View {
    @State var viewModel: PersonsViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.persons.isEmpty {
                FDSEmptyState(
                    symbol: "person.2",
                    title: "No Persons",
                    subtitle: "Run the intelligence pipeline to resolve persons from transactions."
                )
            } else {
                personList
            }
        }
        .task { await viewModel.load() }
        .sheet(item: $viewModel.personToEdit) { person in
            PersonEditSheet(person: person) { updated in
                Task { await viewModel.update(updated) }
            }
        }
        .alert("Delete Person?", isPresented: Binding(
            get: { viewModel.personToDelete != nil },
            set: { if !$0 { viewModel.personToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { viewModel.personToDelete = nil }
            Button("Delete", role: .destructive) {
                if let person = viewModel.personToDelete {
                    viewModel.personToDelete = nil
                    Task { await viewModel.delete(person) }
                }
            }
        } message: {
            if let person = viewModel.personToDelete {
                FDSLabel("Permanently delete \"\(person.canonicalName)\" and all their aliases?")
            }
        }
    }

    private var personList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: AppSpacing.compact) {
                ForEach(viewModel.persons) { person in
                    personCard(person)
                }
            }
            .padding(AppSpacing.xl)
        }
    }

    private func personCard(_ person: Person) -> some View {
        FDSCard(cornerRadius: 12, padded: false) {
            HStack(spacing: AppSpacing.md) {
                personAvatar(person)
                VStack(alignment: .leading, spacing: 3) {
                    FDSLabel(person.canonicalName)
                        .font(AppTypography.bodySmSemibold)
                        .foregroundStyle(AppColors.textPrimary)
                    HStack(spacing: AppSpacing.compact) {
                        if let upi = person.upiHandle {
                            FDSLabel(upi)
                                .font(AppTypography.captionLg)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        FDSLabel("\(person.transactionCount) txns")
                            .font(AppTypography.captionLg)
                            .foregroundStyle(AppColors.textSecondary)
                        FDSLabel("\(person.aliases.count) aliases")
                            .font(AppTypography.captionLg)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                HStack(spacing: AppSpacing.compact) {
                    actionButton("pencil", color: AppColors.textSecondary) {
                        viewModel.personToEdit = person
                    }
                    actionButton("trash", color: AppColors.debit) {
                        viewModel.personToDelete = person
                    }
                }
            }
            .padding(AppSpacing.md)
        }
    }

    private func personAvatar(_ person: Person) -> some View {
        let initial = person.canonicalName.prefix(1).uppercased()
        let hue = Double(abs(person.canonicalName.hashValue) % 360) / 360.0
        let color = Color(hue: hue, saturation: 0.6, brightness: 0.7)
        return ZStack {
            Circle().fill(color.opacity(0.2))
            FDSLabel(initial)
                .font(AppTypography.bodySmSemibold)
                .foregroundStyle(color)
        }
        .frame(width: 36, height: 36)
    }

    private func actionButton(_ icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(AppTypography.captionLgSemibold)
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Edit Sheet

struct PersonEditSheet: View {
    let person: Person
    let onSave: (Person) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var upiHandle: String

    init(person: Person, onSave: @escaping (Person) -> Void) {
        self.person = person
        self.onSave = onSave
        _name = State(initialValue: person.canonicalName)
        _upiHandle = State(initialValue: person.upiHandle ?? "")
    }

    var body: some View {
        FDSSheet(title: "Edit Person", subtitle: person.canonicalName, onDismiss: { dismiss() }, content: {
            VStack(spacing: AppSpacing.xl) {
                FDSCard(cornerRadius: 12, padded: false) {
                    VStack(spacing: 0) {
                        fieldRow("Canonical Name", text: $name)
                        Divider().opacity(0.1)
                        fieldRow("UPI Handle", text: $upiHandle)
                    }
                }
                Button(
                    action: {
                        let updated = Person(
                            id: person.id, canonicalName: name,
                            aliases: person.aliases,
                            upiHandle: upiHandle.isEmpty ? nil : upiHandle,
                            transactionCount: person.transactionCount,
                            firstSeenAt: person.firstSeenAt, lastSeenAt: person.lastSeenAt
                        )
                        onSave(updated)
                        dismiss()
                    },
                    label: {
                        FDSLabel("Save").font(AppTypography.bodySmSemibold)
                            .frame(maxWidth: .infinity).padding(.vertical, AppSpacing.sm)
                            .background(AppColors.accent).foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                )
                .buttonStyle(.plain)
                .disabled(name.isEmpty)
            }
        })
    }

    private func fieldRow(_ label: String, text: Binding<String>) -> some View {
        HStack(spacing: AppSpacing.md) {
            FDSLabel(label).font(AppTypography.captionLgSemibold)
                .foregroundStyle(.tertiary).frame(width: 120, alignment: .leading)
            FDSTextInput("", text: text, style: .bodyMedium)
                .textFieldStyle(.plain)
        }
        .padding(AppSpacing.md)
    }
}
