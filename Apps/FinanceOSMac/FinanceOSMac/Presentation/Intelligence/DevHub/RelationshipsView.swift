import FinanceCore
import FinanceIntelligence
import FinanceUI
import SwiftUI

// MARK: - ViewModel

@MainActor
@Observable
final class RelationshipsViewModel {
    private let repo: any RelationshipRepository
    private let personRepo: any IntelligencePersonRepository
    var relationships: [Relationship] = []
    var persons: [UUID: Person] = [:]
    var isLoading = false
    var relationshipToEdit: Relationship?
    var relationshipToDelete: Relationship?
    var errorMessage: String?

    init(repo: any RelationshipRepository, personRepo: any IntelligencePersonRepository) {
        self.repo = repo
        self.personRepo = personRepo
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            relationships = try await repo.fetchAll()
                .sorted { $0.confidence > $1.confidence }
            let all = try await personRepo.fetchAll()
            persons = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ relationship: Relationship) async {
        do {
            try await repo.delete(id: relationship.id)
            relationships.removeAll { $0.id == relationship.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save(_ relationship: Relationship) async {
        do {
            try await repo.save(relationship)
            if let idx = relationships.firstIndex(where: { $0.id == relationship.id }) {
                relationships[idx] = relationship
            } else {
                relationships.append(relationship)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func personName(for id: String?) -> String {
        guard let id, let uuid = UUID(uuidString: id) else { return id ?? "Unknown" }
        return persons[uuid]?.canonicalName ?? id
    }
}

// MARK: - List View

struct RelationshipsView: View {
    @State var viewModel: RelationshipsViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.relationships.isEmpty {
                FDSEmptyState(
                    symbol: "arrow.triangle.2.circlepath",
                    title: "No Relationships",
                    subtitle: "Run the intelligence pipeline to infer person relationships."
                )
            } else {
                relationshipList
            }
        }
        .task { await viewModel.load() }
        .sheet(item: $viewModel.relationshipToEdit) { rel in
            RelationshipEditSheet(relationship: rel, viewModel: viewModel) { updated in
                Task { await viewModel.save(updated) }
            }
        }
        .alert("Delete Relationship?", isPresented: Binding(
            get: { viewModel.relationshipToDelete != nil },
            set: { if !$0 { viewModel.relationshipToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { viewModel.relationshipToDelete = nil }
            Button("Delete", role: .destructive) {
                if let rel = viewModel.relationshipToDelete {
                    viewModel.relationshipToDelete = nil
                    Task { await viewModel.delete(rel) }
                }
            }
        } message: {
            FDSLabel("Permanently delete this relationship?")
        }
    }

    private var relationshipList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: AppSpacing.compact) {
                ForEach(viewModel.relationships) { rel in
                    relationshipCard(rel)
                }
            }
            .padding(AppSpacing.xl)
        }
    }

    private func relationshipCard(_ rel: Relationship) -> some View {
        FDSCard(cornerRadius: 12, padded: false) {
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: AppSpacing.compact) {
                        FDSLabel(viewModel.personName(for: rel.toPersonId))
                            .font(AppTypography.bodySmSemibold)
                            .foregroundStyle(AppColors.textPrimary)
                        typeBadge(rel.type)
                    }
                    HStack(spacing: AppSpacing.compact) {
                        confidenceBar(rel.confidence)
                        FDSLabel(String(format: "%.0f%%", rel.confidence * 100))
                            .font(AppTypography.captionSm.monospacedDigit())
                            .foregroundStyle(.tertiary)
                        FDSLabel("·  \(rel.evidenceCount) evidence")
                            .font(AppTypography.captionSm)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                HStack(spacing: AppSpacing.compact) {
                    actionButton("pencil", color: AppColors.textSecondary) {
                        viewModel.relationshipToEdit = rel
                    }
                    actionButton("trash", color: AppColors.debit) {
                        viewModel.relationshipToDelete = rel
                    }
                }
            }
            .padding(AppSpacing.md)
        }
    }

    private func typeBadge(_ type: RelationshipType) -> some View {
        let colors: [RelationshipType: Color] = [
            .landlord: .orange, .employer: .green, .family: .purple,
            .friend: .blue, .reimbursement: .cyan, .loanProvider: .red
        ]
        let color = colors[type] ?? AppColors.textSecondary
        return FDSLabel(type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
            // swiftlint:disable:next hardcoded_font_system
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(color.opacity(0.15)).clipShape(Capsule())
    }

    private func confidenceBar(_ confidence: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(AppColors.surface2)
                Capsule().fill(AppColors.accent).frame(width: geo.size.width * confidence)
            }
        }
        .frame(width: 60, height: 4)
    }

    private func actionButton(_ icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(AppTypography.captionLgSemibold)
                .foregroundStyle(color).frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Edit Sheet

struct RelationshipEditSheet: View {
    let relationship: Relationship
    let viewModel: RelationshipsViewModel
    let onSave: (Relationship) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: RelationshipType
    @State private var confidence: Double

    init(relationship: Relationship, viewModel: RelationshipsViewModel, onSave: @escaping (Relationship) -> Void) {
        self.relationship = relationship
        self.viewModel = viewModel
        self.onSave = onSave
        _selectedType = State(initialValue: relationship.type)
        _confidence = State(initialValue: relationship.confidence)
    }

    var body: some View {
        FDSSheet(
            title: "Edit Relationship",
            subtitle: viewModel.personName(for: relationship.toPersonId),
            onDismiss: { dismiss() },
            content: {
            VStack(spacing: AppSpacing.xl) {
                FDSCard(cornerRadius: 12, padded: false) {
                    VStack(spacing: 0) {
                        Picker("Type", selection: $selectedType) {
                            ForEach(RelationshipType.allCases, id: \.self) { type in
                                FDSLabel(type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized).tag(type)
                            }
                        }
                        .pickerStyle(.menu).padding(AppSpacing.md)
                        Divider().opacity(0.1)
                        HStack {
                            FDSLabel("Confidence").font(AppTypography.captionLgSemibold).foregroundStyle(.tertiary)
                            Slider(value: $confidence, in: 0 ... 1)
                            FDSLabel(String(format: "%.0f%%", confidence * 100))
                                .font(AppTypography.captionLg.monospacedDigit()).foregroundStyle(.tertiary)
                        }
                        .padding(AppSpacing.md)
                    }
                }
                Button(
                    action: {
                        let updated = Relationship(
                            id: relationship.id, fromPersonId: relationship.fromPersonId,
                            toPersonId: relationship.toPersonId, type: selectedType,
                            confidence: confidence, evidenceCount: relationship.evidenceCount,
                            signals: relationship.signals, createdAt: relationship.createdAt
                        )
                        onSave(updated); dismiss()
                    },
                    label: {
                        FDSLabel("Save").font(AppTypography.bodySmSemibold)
                            .frame(maxWidth: .infinity).padding(.vertical, AppSpacing.sm)
                            .background(AppColors.accent).foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                )
                .buttonStyle(.plain)
            }
        })
    }
}
