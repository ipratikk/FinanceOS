import FinanceCore
import FinanceIntelligence
import FinanceUI
import SwiftUI

// MARK: - ViewModel

@MainActor
@Observable
final class RecurringPatternsViewModel {
    private let repo: any RecurringPatternRepository
    var patterns: [RecurringPattern] = []
    var isLoading = false
    var patternToEdit: RecurringPattern?
    var patternToDelete: RecurringPattern?
    var errorMessage: String?

    init(repo: any RecurringPatternRepository) {
        self.repo = repo
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            patterns = try await repo.fetchAll()
                .sorted { $0.confidence > $1.confidence }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ pattern: RecurringPattern) async {
        do {
            try await repo.delete(id: pattern.id)
            patterns.removeAll { $0.id == pattern.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save(_ pattern: RecurringPattern) async {
        do {
            try await repo.save(pattern)
            if let idx = patterns.firstIndex(where: { $0.id == pattern.id }) {
                patterns[idx] = pattern
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - List View

struct RecurringPatternsView: View {
    @State var viewModel: RecurringPatternsViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.patterns.isEmpty {
                FDSEmptyState(
                    symbol: "arrow.trianglehead.2.clockwise",
                    title: "No Patterns",
                    subtitle: "Run the intelligence pipeline to detect recurring payments."
                )
            } else {
                patternList
            }
        }
        .task { await viewModel.load() }
        .sheet(item: $viewModel.patternToEdit) { pattern in
            RecurringPatternEditSheet(pattern: pattern) { updated in
                Task { await viewModel.save(updated) }
            }
        }
        .alert("Delete Pattern?", isPresented: Binding(
            get: { viewModel.patternToDelete != nil },
            set: { if !$0 { viewModel.patternToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { viewModel.patternToDelete = nil }
            Button("Delete", role: .destructive) {
                if let pattern = viewModel.patternToDelete {
                    viewModel.patternToDelete = nil
                    Task { await viewModel.delete(pattern) }
                }
            }
        } message: { Text("Permanently delete this recurring pattern?") }
    }

    private var patternList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: AppSpacing.compact) {
                ForEach(viewModel.patterns) { pattern in
                    patternCard(pattern)
                }
            }
            .padding(AppSpacing.xl)
        }
    }

    private func patternCard(_ pattern: RecurringPattern) -> some View {
        FDSCard(cornerRadius: 12, padded: false) {
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: AppSpacing.compact) {
                        FDSLabel(pattern.merchantKey ?? pattern.personId ?? "Unknown")
                            .font(AppTypography.bodySmSemibold).foregroundStyle(AppColors.textPrimary)
                            .lineLimit(1)
                        cadenceBadge(pattern.cadence)
                    }
                    HStack(spacing: AppSpacing.compact) {
                        FDSAmount(
                            FormatterCache.formatCurrency(minorUnits: pattern.averageAmountMinorUnits),
                            type: .debit, size: .small
                        )
                        FDSLabel("·  \(pattern.occurrenceCount)×")
                            .font(AppTypography.captionSm).foregroundStyle(.tertiary)
                        FDSLabel(String(format: "%.0f%% conf.", pattern.confidence * 100))
                            .font(AppTypography.captionSm).foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                HStack(spacing: AppSpacing.compact) {
                    actionButton("pencil", color: AppColors.textSecondary) {
                        viewModel.patternToEdit = pattern
                    }
                    actionButton("trash", color: AppColors.debit) {
                        viewModel.patternToDelete = pattern
                    }
                }
            }
            .padding(AppSpacing.md)
        }
    }

    private func cadenceBadge(_ cadence: RecurringCadence) -> some View {
        FDSLabel(cadence.rawValue.replacingOccurrences(of: "_", with: " "))
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .foregroundStyle(AppColors.accent)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(AppColors.accent.opacity(0.12)).clipShape(Capsule())
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

struct RecurringPatternEditSheet: View {
    let pattern: RecurringPattern
    let onSave: (RecurringPattern) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var merchantKey: String
    @State private var cadence: RecurringCadence
    @State private var confidence: Double

    init(pattern: RecurringPattern, onSave: @escaping (RecurringPattern) -> Void) {
        self.pattern = pattern
        self.onSave = onSave
        _merchantKey = State(initialValue: pattern.merchantKey ?? "")
        _cadence = State(initialValue: pattern.cadence)
        _confidence = State(initialValue: pattern.confidence)
    }

    var body: some View {
        FDSSheet(title: "Edit Pattern", subtitle: pattern.merchantKey ?? "Pattern", onDismiss: { dismiss() }) {
            VStack(spacing: AppSpacing.xl) {
                FDSCard(cornerRadius: 12, padded: false) {
                    VStack(spacing: 0) {
                        HStack(spacing: AppSpacing.md) {
                            FDSLabel("Merchant Key").font(AppTypography.captionLgSemibold)
                                .foregroundStyle(.tertiary).frame(width: 100, alignment: .leading)
                            FDSTextInput("merchant key", text: $merchantKey, style: .bodyMedium)
                                .textFieldStyle(.plain)
                        }
                        .padding(AppSpacing.md)
                        Divider().opacity(0.1)
                        Picker("Cadence", selection: $cadence) {
                            ForEach(RecurringCadence.allCases, id: \.self) { cad in
                                Text(cad.rawValue.replacingOccurrences(of: "_", with: " ")).tag(cad)
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
                Button(action: {
                    let updated = RecurringPattern(
                        id: pattern.id,
                        merchantKey: merchantKey.isEmpty ? nil : merchantKey,
                        personId: pattern.personId,
                        categoryId: pattern.categoryId, intentId: pattern.intentId,
                        cadence: cadence,
                        averageAmountMinorUnits: pattern.averageAmountMinorUnits,
                        amountVariancePercent: pattern.amountVariancePercent,
                        dayOfMonthHint: pattern.dayOfMonthHint,
                        confidence: confidence,
                        occurrenceCount: pattern.occurrenceCount,
                        lastSeenAt: pattern.lastSeenAt, createdAt: pattern.createdAt
                    )
                    onSave(updated); dismiss()
                }) {
                    FDSLabel("Save").font(AppTypography.bodySmSemibold)
                        .frame(maxWidth: .infinity).padding(.vertical, AppSpacing.sm)
                        .background(AppColors.accent).foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
